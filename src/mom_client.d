interface mom_client
{
	// set callback function for listener ()
	public void set_callback(void function(byte* txt, ulong size, mom_client from_client) _message_acceptor);

	// in thread listens to the queue and calls _message_acceptor
	public void listener();
	
	// sends a message to the specified queue
	public int send(char* routingkey, char* messagebody,  bool send_more);

	// forward to receiving the message
	public char* get_message ();
	
	//
	public char[] getInfo ();
}