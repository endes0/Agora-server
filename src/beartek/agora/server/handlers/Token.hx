//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Protocol_types;

class Token {
  var clients_tokens : Array<haxe.io.Bytes> = new Array();

  public function new() {
    Main.connection.register_join_handler(this.on_new_client);
    Main.connection.register_left_handler(this.on_client_left);
    Main.connection.register_get_handler('token', this.on_token_request);
  }

  public function generate_token() : haxe.io.Bytes {
    var token : haxe.io.Bytes = haxe.io.Bytes.alloc(Math.floor(Math.random() * 20 +2));

    for( i in 0...token.length ) {
      token.fill(i, 1, Math.round(Math.random()));
    }

    if( clients_tokens.indexOf(token) != -1 ) {
      token = generate_token();
    }
    return token;
  }

  public inline function set_token( id : Int, token : haxe.io.Bytes ) : Void {
    clients_tokens[id] = token;
  }

  public inline function get_token( id : Int ) : haxe.io.Bytes {
    return clients_tokens[id];
  }

  private function on_new_client( id : Int ) : Void {
    this.set_token(id, generate_token());
  }

  private function on_client_left( id : Int ) : Void {
    clients_tokens[id] = null;
  }

  private function on_token_request( id : Int, conn_id : String, nothing : Dynamic ) : Void {
    var token : haxe.io.Bytes = this.get_token(id);
    if( token == null || token.length < 2 ) {
      this.on_new_client(id);
      token = this.get_token(id);
    }

    Main.connection.send_token(token, id, conn_id);
  }

}
