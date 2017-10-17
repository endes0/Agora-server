//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Protocol_types;
import beartek.agora.types.Tid;
import siphash.SipHash;
import datetime.DateTime;

@:keep class Sessions {
  public var sessions(default,null) : Array<Tid> = new Array();
  var table : models.AuthManager = Main.db.auth;
  var login : models.LoginkeyManager = Main.db.loginkey;
  var sh : SipHash = new SipHash();

  public function new() {
    Main.connection.register_left_handler(this.on_client_left);
    Main.connection.register_get_handler('auth', this.on_auth_request);
    Main.connection.register_create_handler('privkey', this.on_privkey_request);
    Main.connection.register_create_handler('privkey_with_login', this.on_privkey_with_loginkey_request);
  }

  public function new_privkey( id : Int ) : haxe.io.ArrayBufferView {
    var privkey : haxe.io.Int32Array = this.generate_privkey();
    table.create(haxe.Serializer.run(privkey.view), '', sessions[id].toString(), DateTime.now().toString());
    return privkey.view;
  }

  public function new_privkey_with_loginkey( loginkey : haxe.Int64 ) : Null<haxe.io.ArrayBufferView> {
    var login : models.Loginkey = login.get(haxe.Serializer.run(loginkey));

    if( login != null ) {
      var privkey : haxe.io.Int32Array = this.generate_privkey();
      table.create(haxe.Serializer.run(privkey.view), '', login.user_id, DateTime.now().toString());
      return privkey.view;
    } else {
      trace( 'Invalid loginkey' );
      return null;
    }
  }

  public function valid_auth( session_key : haxe.Int64, token : haxe.io.Bytes ) : Bool {
    var auths = table.getAll();
    for( auth in auths ) {
      var privkey : haxe.io.Int32Array = haxe.Unserializer.run(auth.privkey);
      if( sh.reset(privkey).fast(token) == session_key ) {
        this.update_last_use(privkey);
        return true;
      }
    }

    return false;
  }

  public function auth( session_key : haxe.Int64, token : haxe.io.Bytes ) : Null<Tid> {
    var auths = table.getAll();
    for( auth in auths ) {
      var privkey : haxe.io.Int32Array = haxe.Unserializer.run(auth.privkey);
      if( sh.reset(privkey).fast(token) == session_key ) {
        this.update_last_use(privkey);
        return Tid.fromString(auth.user_id);
      }
    }

    trace( 'Fail on auth' );
    return null;
  }

  private function update_last_use( privkey : haxe.io.Int32Array ) : Void {
    table.where('privkey', '=', haxe.Serializer.run(privkey)).update([ 'last_use' => DateTime.now().toString() ]);
  }

  public function generate_loginkey( username : String, password : String ) : haxe.Int64 {
    if( password.length > 59 ) {
      throw 'password too long.';
    }

    var sh = new siphash.SipHash();

    var pass : haxe.io.Int32Array = new haxe.io.Int32Array(4);
    for( pos in 0...password.length ) {
      var i : Int = Math.floor(pos/15);
      pass[i] = ((pass[i] << 2) + password.charCodeAt(pos));
    }
    return sh.reset(pass).fast(haxe.io.Bytes.ofString(username));
  }

  private function generate_privkey() : haxe.io.Int32Array {
    var privkey : haxe.io.Int32Array = new haxe.io.Int32Array(4);
    for( i in 0...3 ) {
      var r : Int = Math.round( (Math.random()*1000 * Math.pow(Math.round(Math.random() * 10), 10)) % 2000000000 );
      privkey[i] = r;
    }
    return privkey;
  }

  private function on_privkey_request( id : Int, conn_id : String, nothing : Dynamic ) : Void {
    if( sessions[id] != null ) {
      Main.connection.send_privkey(this.new_privkey(id), id, conn_id);
    } else {
      //Main.connection.send_error();
    }
  }

  private function on_privkey_with_loginkey_request( id : Int, conn_id : String, loginkey : haxe.Int64 ) : Void {
    var privkey : haxe.io.ArrayBufferView = this.new_privkey_with_loginkey(loginkey);
    if( privkey != null ) {
      Main.connection.send_privkey(privkey, id, conn_id);
    } else {
      //Main.connection.send_error();
    }
  }

  private function on_auth_request( id : Int, conn_id : String, session_key : haxe.Int64 ) : Void {
    var user : Tid = this.auth(session_key, Main.handlers.token.get_token(id));

    if( user != null ) {
      sessions[id] = user;
      Main.connection.send_auth(true, id, conn_id);
    } else {
      Main.connection.send_auth(false, id, conn_id);
    }
  }

  private function on_client_left( id : Int ) : Void {
    sessions[id] = null;
  }
}
