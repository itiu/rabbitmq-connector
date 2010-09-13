private import tango.io.Stdout;
private import tango.stdc.string;
private import tango.net.device.Socket;
private import tango.stdc.stringz;
private import tango.stdc.stdio;

private import mom_client;

private import amqp_base;
private import amqp;
private import amqp_framing;
private import amqp_private;
private import amqp_connection;
private import amqp_socket;
private import amqp_api;
private import amqp_mem;
private import Log;

private import tango.core.Thread;

class librabbitmq_client: mom_client
{
	amqp_connection_state_t *conn;
	char[] vhost;
	char[] login;
	char[] passw;
	char* bindingkey = null;
	char* exchange = cast(char*) "\0";

	int waiting_for_login = 5;
	Socket socket;

	char[] hostname;
	int port;
	void function(byte* txt, ulong size, mom_client from_client) message_acceptor;
	
	public char[] getInfo ()
	{
		return "rabbitmq";
	}
	
	this(char[] _hostname, int _port, char[] _login, char[] _passw, char[] _queue, char[] _vhost)
	{
		hostname = _hostname;
		port = _port;
		login = _login;
		passw = _passw;
		bindingkey = cast(char*)_queue;
		vhost = _vhost;
	}

	void set_callback(void function(byte* txt, ulong size, mom_client from_client) _message_acceptor)
	{
		message_acceptor = _message_acceptor;
	}

	int send(char* routingkey, char* messagebody, bool send_more)
	{

		amqp_basic_properties_t props;

		props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
		props.content_type = amqp_cstring_bytes("text/plain");
		props.delivery_mode = 1; // non-persistent delivery mode

		//		printf("lc#3\n");
		//			Thread.sleep(15.650);


		//		//		printf("%s \n", conn);
		       //exchange, routingkey, props, messagebody);

		//log.trace("basic publish start");
		int result_publish = amqp_basic_publish(conn, 1, amqp_cstring_bytes(exchange), amqp_cstring_bytes(routingkey), 0, 0, &props,
							amqp_cstring_bytes(messagebody));
		//log.trace("basic publish end");
		int i = 0;
		while(socket is null || i++ > 100)
		{
			log.trace("Socket is NULL!!!");
		}

		//		printf("lc#4\n");

		return result_publish;
	}

       	char* get_message () {
		return null;
	}

	void listener()
	{
		//		amqp_connection_state_t_ conn;

		//		printf("lc#1\n");

		int i = 0;
		while(true)
		{
			bool is_connect_succsess = false;
			while(!is_connect_succsess)
			{
				Stdout.format("\nlistener:connect to AMQP server {}:{}", hostname, port).newline;

				socket = amqp_open_socket(hostname, port);

				if(socket.native().sock < 0)
					Stdout.format("connection faled, errcode={} ", socket).newline;
				else
					Stdout.format("connection is ok, code={}", socket.native().sock).newline;

//				if(socket.sock == 4)
				{

					Stdout.format("trying to connect...").newline;

					conn = amqp_new_connection(socket);

					Stdout.format("connection={:X4} ", conn).newline;

					amqp_rpc_reply_t res_login;

					res_login = amqp_login(conn, cast(char*) vhost, 0, 131072, 0, amqp_sasl_method_enum.AMQP_SASL_METHOD_PLAIN, cast(char*) login,
							cast(char*) passw);
					Stdout.format("login state={}", res_login.reply_type).newline;

					if(res_login.reply_type == 1)
					{
						is_connect_succsess = true;
						amqp_channel_open(conn, 1);
					}

				}
				if(!is_connect_succsess)
					Thread.sleep(waiting_for_login);
			}

			amqp_table_t arguments;
			arguments.num_entries = 0;
			arguments.entries = null;

			amqp_rpc_reply_t result;
			amqp_bytes_t queuename;

			try
			{
				//				#define AMQP_EMPTY_BYTES ((amqp_bytes_t) { .len = 0, .bytes = NULL }) 
				amqp_bytes_t AMQP_EMPTY_BYTES;
				AMQP_EMPTY_BYTES.len = tango.stdc.string.strlen(bindingkey);
				AMQP_EMPTY_BYTES.bytes = bindingkey;

				//				#define AMQP_EMPTY_TABLE ((amqp_table_t) { .num_entries = 0, .entries = NULL }) 
				amqp_table_t AMQP_EMPTY_TABLE;
				AMQP_EMPTY_TABLE.num_entries = 0;
				AMQP_EMPTY_TABLE.entries = null;

				amqp_queue_declare_ok_t* r = amqp_queue_declare(conn, 1, AMQP_EMPTY_BYTES, 0, 0, 0, 0, AMQP_EMPTY_TABLE);
				//				die_on_amqp_error(amqp_rpc_reply, "Declaring queue");
				/*				queuename = amqp_bytes_malloc_dup(r.queue);
				if(queuename.bytes is null)
				{
					throw new Exception("Declaring queue:Copying queue name");
					}*/
				Stdout.format("declare ok").newline;
			}
			catch(Exception ex)
			{
				printf("bindingkey=[%s] \n", bindingkey);
				Stdout.format("Exception in:{}, amqp_queue_declare\n", ex).newline;;
				throw ex;
			}

			/*			try
			{
				//				#define AMQP_EMPTY_TABLE ((amqp_table_t) { .num_entries = 0, .entries = NULL }) 
				amqp_table_t AMQP_EMPTY_TABLE;
				AMQP_EMPTY_TABLE.num_entries = 0;
				AMQP_EMPTY_TABLE.entries = null;

//				amqp_queue_bind(conn, 1, queuename, amqp_cstring_bytes(exchange), amqp_cstring_bytes(bindingkey), AMQP_EMPTY_TABLE);

				Stdout.format("Binding queue ok").newline;
			}
			catch(Exception ex)
			{
				Stdout.format("Exception in: Binding queue");
				throw ex;
				}*/

			try
			{
				//				#define AMQP_EMPTY_BYTES ((amqp_bytes_t) { .len = 0, .bytes = NULL }) 
				amqp_bytes_t AMQP_EMPTY_BYTES;
				AMQP_EMPTY_BYTES.len = 0;
				AMQP_EMPTY_BYTES.bytes = null;

				amqp_basic_consume(conn, 1, amqp_cstring_bytes(bindingkey), AMQP_EMPTY_BYTES, 0, 1, 0);

				Stdout.format("Consuming ok").newline;
			}
			catch(Exception ex)
			{
				Stdout.format("Exception in: Consuming");
				throw ex;
			}

			{

				//Stdou.format("amqp#0").newline;

				amqp_frame_t frame;
				int result_listen;

				amqp_basic_deliver_t* d;
				amqp_basic_properties_t* p;
				size_t body_target;
				size_t body_received;

				while(true)
				{
					//Stdou.format("amqp#1").newline;
					i = 0;
					while(socket is null || i++ > 100)
					{
						log.trace("Socket is NULL!!!");
					}

					//log.trace("#release buffers start");
					

					amqp_maybe_release_buffers(conn);

					//log.trace("#release buffers end");

					//log.trace("incoming message...recieving started : wait 1");
					i = 0;

					while(socket is null || i++ > 100)
					{
						log.trace("Socket is NULL!!!");
					}
					//log.trace("#wait 1 start");
					
					result_listen = amqp_simple_wait_frame(conn, &frame);

					//log.trace("#wait 1 end");
					i = 0;
					while(socket is null || i++ > 100)
					{
						log.trace("Socket is NULL!!!");
					}
					//					printf("Result %d\n", result);
					if(result_listen <= 0)
					{
						//log.trace("result_listen {} <= 0, -> break", result_listen);
						break;
						//continue;
					}

					//Stdou.format("Frame type {}, channel {}", frame.frame_type, frame.channel).newline;
					if(frame.frame_type != AMQP_FRAME_METHOD) {
						//log.trace("frame.frame_type != AMQP_FRAME_METHOD");
						continue;
					}
					//Stdou.format("amqp#2").newline;

					//Stdou.format("Payload method = {}", frame.payload.method.id).newline;

					//					char* ptr = cast(char*) &frame;

					//					amqp_method_number_t frame_payload_method_id = frame.payload.method.id;
					/*					uint* ptr_frame_payload_method_decoded = cast(uint*) (cast(void*) &frame + 8);
					size_t* ptr_frame_payload_body_fragment_len = cast(uint*) (cast(void*) &frame + 4);
					uint* ptr_frame_payload_body_fragment_bytes = cast(uint*) (cast(void*) &frame + 8);
					uint16_t* ptr_frame_payload_properties_class_id = cast(uint16_t*) (cast(void*) &frame + 6); // ? uint64_t
					uint16_t* ptr_frame_payload_properties_body_size = cast(uint16_t*) (cast(void*) &frame + 8);
					uint* ptr_frame_payload_properties_decoded = cast(uint*) (cast(void*) &frame + 10);*/

					//Stdou.format("Payload method = {}", frame.payload.method.id).newline;

					if(frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD) {
						//log.trace("frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD");
						continue;
					}

					//Stdou.format("amqp#3").newline;

					d = cast(amqp_basic_deliver_t*) frame.payload.method.decoded;
					/*
					 printf("Delivery %u, exchange %.*s routingkey %.*s\n",
					 (unsigned) d->delivery_tag,
					 (int) d->exchange.len, (char *) d->exchange.bytes,
					 (int) d->routing_key.len, (char *) d->routing_key.bytes);
					 */

					//log.trace("incoming message...recieving started : wait 2");
					i = 0;
					while(socket is null || i++ > 100)
					{
						log.trace("Socket is NULL!!!");
					}

					
					//log.trace("wait 2 start");
					
					result_listen = amqp_simple_wait_frame(conn, &frame);

					//log.trace("wait 2 end");

					i = 0;
					while(socket is null || i++ > 100)
					{
						log.trace("Socket is NULL!!!");
					}

					if(result_listen <= 0)
					{
						//log.trace("result_listen2 {} <= 0, -> break", result_listen);
						break;
					}

					if(frame.frame_type != AMQP_FRAME_HEADER)
					{
						//log.trace("Expected header! frame.frame_type={}", frame.frame_type);
						return;
						//        abort();
					}

					p = cast(amqp_basic_properties_t*) frame.payload.properties.decoded;

					/*					if(p._flags & AMQP_BASIC_CONTENT_TYPE_FLAG)
					{
						printf("Content-type: %.*s\n",
						       cast(int) p.content_type.len, cast(char *) p.content_type.bytes);
						       }*/

					body_target = frame.payload.properties.body_size;
					body_received = 0;

					//Stdou.format("result body_target={} class_id={}", body_target,
					//					      frame.payload.properties.class_id).newline;
					
					//log.trace("incoming message...recieving started");
					while(body_received < body_target)
					{
						//log.trace("incoming message...recieving started : wait 3");
						i = 0;
						while(socket is null || i++ > 100)
						{
							log.trace("Socket is NULL!!!");
						}

						
						//log.trace("#wait 3 start");
						
						result_listen = amqp_simple_wait_frame(conn, &frame);

						//log.trace("#wait 3 end");

						i = 0;
						while(socket is null || i++ > 100)
						{
							log.trace("Socket is NULL!!!");
						}
						if(result_listen <= 0)
						{
							//log.trace("result_listen3 {} <= 0, -> break", result_listen);
							break;
						}

						if(frame.frame_type != AMQP_FRAME_BODY)
						{
							//log.trace("Expected body!, frame.type={}", frame.frame_type);
							return;
						}

						body_received += frame.payload.body_fragment.len;
						/*
						 Stdout.format("body_received={} *ptr_frame_payload_body_fragment_bytes={} *ptr_frame_payload_body_fragment_len={}", 
						 body_received, *ptr_frame_payload_body_fragment_bytes, *ptr_frame_payload_body_fragment_len).newline;
						 */

						assert(body_received <= body_target);

						/*
						 amqp_dump(cast(void*) *ptr_frame_payload_body_fragment_bytes, *ptr_frame_payload_body_fragment_len);
						 printf("data: %.*s\n", *ptr_frame_payload_body_fragment_len, cast(void*) *ptr_frame_payload_body_fragment_bytes);
						 */

						//log.trace("incoming message...recieved");
						byte* message = cast(byte*) frame.payload.body_fragment.bytes;

						//log.trace("#message acceptor start");
						
						message_acceptor(message, frame.payload.body_fragment.len, this);

						//log.trace("#message acceptor end");
						
					}
					//					printf("DeliveryTag %u\n", d.delivery_tag);
					//amqp_basic_ack(conn, 1, d.delivery_tag, 0);


					//			if(body_received != body_target)
					//			{
					/* Can only happen when amqp_simple_wait_frame returns <= 0 */
					/* We break here to close the connection */
					//				break;
					//			}
				}
			}

		}

	}

}
/*
 void die_on_amqp_error(amqp_rpc_reply_t_ x, char *context) 
 { 
 fprintf(stderr, "!!!0"); 
 
 switch (x.reply_type) { 
 case AMQP_RESPONSE_NORMAL: 
 return; 
 
 case AMQP_RESPONSE_NONE: 
 fprintf(stderr, "%s: missing RPC reply type!", context); 
 break; 
 
 case AMQP_RESPONSE_LIBRARY_EXCEPTION: 
 fprintf(stderr, "%s: %s\n", context, 
 x.library_errno ? strerror(x.library_errno) : "(end-of-stream)"); 
 break; 
 
 case AMQP_RESPONSE_SERVER_EXCEPTION: 
 switch (x.reply.id) { 
 case AMQP_CONNECTION_CLOSE_METHOD: { 
 fprintf(stderr, "!!!1"); 

 
 amqp_connection_close_t *m = (amqp_connection_close_t_ *) x.reply.decoded; 
 fprintf(stderr, "%s: server connection error %d, message: %.*s", 
 context, 
 m.reply_code, 
 (int) m.reply_text.len, (char *) m.reply_text.bytes);
 
 
 break; 
 } 
 case AMQP_CHANNEL_CLOSE_METHOD: { 
 fprintf(stderr, "!!!2"); 
 
 amqp_channel_close_t *m = (amqp_channel_close_t *) x.reply.decoded; 
 fprintf(stderr, "%s: server channel error %d, message: %.*s", 
 context, 
 m.reply_code, 
 (int) m.reply_text.len, (char *) m.reply_text.bytes); 
 
 break; 
 } 
 default: 
 fprintf(stderr, "%s: unknown server error, method id 0x%08X", context, x.reply.id); 
 break; 
 } 
 break; 
 } 
 
 exit(1); 
 }
 */
