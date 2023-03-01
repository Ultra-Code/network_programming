const std = @import("std");
const mem = std.mem;
const cnet = @import("cnet.zig");
const AddressInfo = cnet.AddressInfo;

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.c_allocator);
    if (argv.len != 2) {
        std.log.err("usage: showip hostname\n", .{});
        std.process.exit(2);
    }
    const program_arg = argv[1];

    var address_info = AddressInfo{
        .data = .{
            .ai_family = cnet.AF_UNSPEC,
            .ai_socktype = cnet.SOCK_STREAM,
            .ai_protocol = undefined,
            .ai_addrlen = undefined,
            .ai_addr = undefined,
            .ai_canonname = undefined,
            .ai_next = undefined,
            .ai_flags = undefined,
        },
    };

    address_info.getaddrinfo_status = cnet.getaddrinfo(
        program_arg,
        "https",
        &address_info.data,
        &address_info.serviceinfo,
    );
    defer cnet.freeaddrinfo(address_info.serviceinfo);

    if (address_info.getaddrinfo_status != 0) {
        std.log.err(
            "getaddrinfo error: {s}",
            .{cnet.gai_strerror(address_info.getaddrinfo_status)},
        );
        std.process.exit(1);
    }

    std.debug.print("The IP address of {s}", .{program_arg});

    var address_list = address_info.serviceinfo;

    //iterate addresses in linked list `address_info.serviceinfo`
    while (address_list != null) : (address_list = address_list.?.ai_next) {
        if (address_list.?.ai_family == cnet.AF_INET) {
            var ip_buf: [cnet.INET_ADDRSTRLEN]u8 = undefined;

            var ipv4: *cnet.sockaddr_in =
                @ptrCast(
                *cnet.sockaddr_in,
                @alignCast(@alignOf(@TypeOf(address_list.?.ai_addr)), address_list.?.ai_addr),
            );

            const ip_str: ?[*:0]const u8 = cnet.inet_ntop(
                address_list.?.ai_family,
                @ptrCast(*anyopaque, &ipv4.sin_addr),
                ip_buf[0..],
                cnet.INET_ADDRSTRLEN,
            );

            if (ip_str) |ip| {
                std.debug.print(" {s}: {s}\n", .{ "IPV4", ip });
            } else {
                std.log.err("{s}", .{cnet.strerror(std.c._errno().*)});
            }
        } else {
            var ip_buf: [cnet.INET6_ADDRSTRLEN]u8 = undefined;

            var ipv6: *cnet.sockaddr_in6 =
                @ptrCast(
                *cnet.sockaddr_in6,
                @alignCast(@alignOf(@TypeOf(address_list.?.ai_addr)), address_list.?.ai_addr),
            );

            const ip_str: ?[*:0]const u8 = cnet.inet_ntop(
                address_list.?.ai_family,
                @ptrCast(*anyopaque, &ipv6.sin6_addr),
                ip_buf[0..],
                cnet.INET6_ADDRSTRLEN,
            );

            if (ip_str) |ip| {
                std.debug.print(" {s}: {s}\n", .{ "IPV6", ip });
            } else {
                std.log.err("{s}", .{cnet.strerror(std.c._errno().*)});
            }
        }
    }
}

test "simple test" {}
