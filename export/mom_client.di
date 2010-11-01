// D import file generated from 'src/mom_client.d'
interface mom_client
{
    public void set_callback(void function(byte* txt, ulong size, mom_client from_client) _message_acceptor);

    public void listener();

    public int send(char* routingkey, char* messagebody, bool send_more);

    public char* get_message();

    public char[] getInfo();

}
