const std = @import("std");
const mem = std.mem;
const cnet = @import("cnet.zig");
const AddressInfo = cnet.AddressInfo;

const SUCCESS = 0;
const ERROR = -1;

//creates an endpoint for communication
fn server(service_info: *cnet.addrinfo) void {
    const socket_fd = cnet.socket(
        service_info.ai_family,
        service_info.ai_socktype,
        service_info.ai_protocol,
    );
    if (socket_fd == ERROR) {
        std.log.err("socket failed:{s}", .{cnet.strerror(std.c._errno().*)});
        std.process.exit(3);
    }

    //assigns the address specified by addr to the socket referenced by
    //`socket_fd`
    cnet.bind(socket_fd, service_info.ai_addr, service_info.ai_addrlen);
}

pub fn main() !void {
    const argv = try std.process.argsAlloc(std.heap.c_allocator);
    if (argv.len != 2) {
        std.log.err("usage: showip hostname\n", .{});
        std.process.exit(2);
    }
    const program_arg = argv[1];

    var address_info = AddressInfo{
        .data = .{
            .ai_family = cnet.AF_UNSPEC, //support both IPv4 or IPv6
            .ai_socktype = cnet.SOCK_STREAM, //TCP stream sockets
            .ai_protocol = undefined,
            .ai_addrlen = undefined,
            .ai_addr = undefined,
            .ai_canonname = undefined,
            .ai_next = undefined,
            //AI_PASSIVE means to assign address of localhost to socket
            .ai_flags = undefined,
        },
    };

    const service_name_or_port = "https";
    //network address and service translation
    address_info.getaddrinfo_status = cnet.getaddrinfo(
        program_arg,
        service_name_or_port,
        &address_info.data,
        &address_info.serviceinfo,
    );
    defer cnet.freeaddrinfo(address_info.serviceinfo);

    if (address_info.getaddrinfo_status != SUCCESS) {
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

            var ipv4: *cnet.sockaddr_in = @ptrCast(@alignCast(address_list.?.ai_addr));

            const ip_str: ?[*:0]const u8 = cnet.inet_ntop(
                address_list.?.ai_family,
                @ptrCast(&ipv4.sin_addr),
                ip_buf[0..],
                cnet.INET_ADDRSTRLEN,
            );

            if (ip_str) |ip| {
                std.debug.print(" {s}: {s}\n", .{ "IPV4", ip });
            } else {
                std.log.err("inet_ntop failed:{s}", .{cnet.strerror(std.c._errno().*)});
            }
        } else {
            var ip_buf: [cnet.INET6_ADDRSTRLEN]u8 = undefined;

            var ipv6: *cnet.sockaddr_in6 = @ptrCast(@alignCast(address_list.?.ai_addr));

            const ip_str: ?[*:0]const u8 = cnet.inet_ntop(
                address_list.?.ai_family,
                @ptrCast(&ipv6.sin6_addr),
                ip_buf[0..],
                cnet.INET6_ADDRSTRLEN,
            );

            if (ip_str) |ip| {
                std.debug.print(" {s}: {s}\n", .{ "IPV6", ip });
            } else {
                std.log.err("inet_ntop failed:{s}", .{cnet.strerror(std.c._errno().*)});
            }
        }
    }
}

test "simple test" {}
