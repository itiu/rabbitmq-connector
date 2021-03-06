// D import file generated from 'src/amqp_private.d'
import tango.net.device.Socket;
import tango.stdc.string;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import amqp_base;
import amqp;
enum amqp_connection_state_enum 
{
CONNECTION_STATE_IDLE = 0,
CONNECTION_STATE_WAITING_FOR_HEADER,
CONNECTION_STATE_WAITING_FOR_BODY,
CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER,
}
const HEADER_SIZE = 7;
const FOOTER_SIZE = 1;
struct amqp_link_t
{
    amqp_link_t* next;
    void* data;
}
struct amqp_connection_state_t
{
    amqp_pool_t frame_pool;
    amqp_pool_t decoding_pool;
    amqp_connection_state_enum state;
    int channel_max;
    int frame_max;
    int heartbeat;
    amqp_bytes_t inbound_buffer;
    size_t inbound_offset;
    size_t target_size;
    amqp_bytes_t outbound_buffer;
    Socket socket;
    amqp_bytes_t sock_inbound_buffer;
    size_t sock_inbound_offset;
    size_t sock_inbound_limit;
    amqp_link_t* first_queued_frame;
    amqp_link_t* last_queued_frame;
}
template CL(T)
{
T CHECK_LIMIT(amqp_bytes_t b, int o, int l, T v)
{
assert(o + l <= b.len);
return v;
}
}
public 
{
    static 
{
    uint8_t* BUF_AT(amqp_bytes_t b, int o)
{
return &(cast(uint8_t*)b.bytes)[o];
}
}
}
public 
{
    static 
{
    uint8_t D_8(amqp_bytes_t b, int o)
{
return CL!(uint8_t).CHECK_LIMIT(b,o,1,*cast(uint8_t*)BUF_AT(b,o));
}
}
}
public 
{
    static 
{
    uint16_t D_16(amqp_bytes_t b, int o)
{
uint16_t v;
memcpy(&v,BUF_AT(b,o),2);
return CL!(uint16_t).CHECK_LIMIT(b,o,2,_htons(v));
}
}
}
public 
{
    static 
{
    uint32_t D_32(amqp_bytes_t b, int o)
{
uint32_t v;
memcpy(&v,BUF_AT(b,o),4);
return CL!(uint32_t).CHECK_LIMIT(b,o,4,_htonl(v));
}
}
}
public 
{
    static 
{
    uint64_t D_64(amqp_bytes_t b, int o)
{
uint64_t hi = D_32(b,o);
uint64_t lo = D_32(b,o + 4);
return hi << 32 | lo;
}
}
}
public 
{
    static 
{
    uint8_t* D_BYTES(amqp_bytes_t b, int o, int l)
{
return CL!(uint8_t*).CHECK_LIMIT(b,o,l,BUF_AT(b,o));
}
}
}
public 
{
    static 
{
    uint8_t E_8(amqp_bytes_t b, int o, uint8_t v)
{
*cast(uint8_t*)BUF_AT(b,o) = v;
return CL!(uint8_t).CHECK_LIMIT(b,o,1,*cast(uint8_t*)BUF_AT(b,o));
}
}
}
public 
{
    static 
{
    uint16_t E_16(amqp_bytes_t b, int o, uint16_t v)
{
uint16_t vv = _htons(v);
memcpy(BUF_AT(b,o),&vv,2);
return CL!(uint16_t).CHECK_LIMIT(b,o,2,vv);
}
}
}
public 
{
    static 
{
    uint32_t E_32(amqp_bytes_t b, int o, uint32_t v)
{
uint32_t vv = _htonl(v);
memcpy(BUF_AT(b,o),&vv,4);
return CL!(uint32_t).CHECK_LIMIT(b,o,4,vv);
}
}
}
public 
{
    static 
{
    uint64_t E_64(amqp_bytes_t b, int o, int v)
{
E_32(b,o,cast(uint32_t)(cast(uint64_t)v >> 32));
return E_32(b,o + 4,cast(uint32_t)(cast(uint64_t)v & -1u));
}
}
}
public 
{
    static 
{
    void E_BYTES(amqp_bytes_t b, int o, int l, void* v)
{
CL!(void*).CHECK_LIMIT(b,o,l,memcpy(BUF_AT(b,o),v,l));
}
}
}
public 
{
    static 
{
    void amqp_assert(bool condition,...);
}
}
public 
{
    static 
{
    int AMQP_CHECK_EOF_RESULT(int expr);
}
}
public 
{
    static 
{
    void amqp_dump(void* buffer, size_t len)
{
return cast(void)0;
}
}
}
version (BigEndian)
{
    private 
{
    ushort _htons(ushort x)
{
return x;
}
}
    private 
{
    uint _htonl(uint x)
{
return x;
}
}
}
else
{
    private 
{
    import tango.core.BitManip;
}
    private 
{
    ushort _htons(ushort x)
{
return cast(ushort)(x >> 8 | x << 8);
}
}
    private 
{
    uint _htonl(uint x)
{
return bswap(x);
}
}
}
