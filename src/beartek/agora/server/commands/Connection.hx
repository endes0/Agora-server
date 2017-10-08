//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.commands;


class Connection {

  public function new() {
    Main.handlers.commands.register_handler('clients', this.clients);
    Main.handlers.commands.register_handler('client_send', this.client_send);

  }

  public function clients( cmd : Array<String> ) : Bool {
    trace( 'There are ' + Main.connection.n_clients + ' clients connected now.' );
    return true;
  }

  public function client_send( cmd : Array<String> ) : Bool {
    var client : Int = Std.parseInt(cmd[1]);
    var conn : String = cmd[2];

    if(cmd.length < 4) throw 'Insufficient arguments.';
    if( client == null || client +1 > Main.connection.n_clients ) throw 'Unknow client id';

    switch cmd[3] {
    case 'auth':
      Main.connection.send_auth(if(cmd[4] == 'false') false else true, client, conn);
    case 'privkey':
      Main.connection.send_privkey(haxe.io.Int32Array.fromArray([Std.parseInt(cmd[4]), Std.parseInt(cmd[5]), Std.parseInt(cmd[6]), Std.parseInt(cmd[7])]), client, conn);
    case 'post_removed':
      Main.connection.send_post_removed(if(cmd[4] == 'false') false else true, client, conn);
    case _:
      trace( 'Not found response to send.' );
      return false;
    }
    //TODO: anadir mas subcomandos

    return true;
  }


}
