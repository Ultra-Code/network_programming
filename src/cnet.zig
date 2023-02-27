const Self = @This();
//socket network programming
pub usingnamespace @cImport({
    //sys/types.h — data types
    @cInclude("sys/types.h");
    //sys/socket.h — main sockets header
    @cInclude("sys/socket.h");
    //netdb.h — definitions for network database operations
    @cInclude("netdb.h");
    //inet_ntop - convert IPv4 and IPv6 addresses from binary to text form
    @cInclude("arpa/inet.h");
    //The  strerror()  function  returns a pointer to a string that describes the error code
    @cInclude("string.h");
});

pub const AddressInfo = struct {
    getaddrinfo_status: @typeInfo(@TypeOf(Self.getaddrinfo)).Fn.return_type.? = undefined,
    data: Self.addrinfo,
    serviceinfo: ?*Self.addrinfo = undefined,
};
