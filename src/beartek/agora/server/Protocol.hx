//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;
import beartek.agora.types.Protocol_types;
import beartek.agora.types.Types;
import beartek.agora.types.Tpost;
import beartek.agora.types.Tid;
import beartek.agora.types.Tsentence;


class Protocol extends Wtps {
  var get_handlers : Map<String,Array<Int -> String -> Dynamic -> Void>> = new Map();
  var create_handlers : Map<String,Array<Int -> String -> Dynamic -> Void>> = new Map();
  var remove_handlers : Map<String,Array<Int -> String -> Dynamic -> Void>> = new Map();

  var join_handlers : Array<Int -> Void> = new Array();
  var left_handlers : Array<Int -> Void> = new Array();

  public function new(host : String, port: Int = 8080, max: Int = 100, ?secure_path : {CA: String, Certificate: String}, debug : Bool = true) {
    super(host, port, max, secure_path, debug);
  }

  override public function on_new_client( id : Int ) : Void {
    for( func in join_handlers ) {
      func(id);
    }
  }

  override public function on_client_left( id : Int ) : Void {
    for( func in left_handlers ) {
      func(id);
    }
  }

  override public function on_pet( client_id : Int, pet : {id: String, type: Pet_types, data: Dynamic} ) : Void {
    switch pet.type {
    case Get(d): this.process_get(client_id, pet.id, d, pet.data);
    case Create(d): this.process_create(client_id, pet.id, d, pet.data);
    case Remove(d): this.process_remove(client_id, pet.id, d, pet.data);
    }
  }

  private function process_get(client_id : Int, pet_id : String, type : String, data: Dynamic) : Void {
    if( get_handlers[type] != null ) {
      for( func in get_handlers[type] ) {
        try {
          func(client_id, pet_id, data);
        } catch(e:Dynamic) {
          trace('Error executing get handler for ' + pet_id + ': ' + e, 'error');
          trace( haxe.CallStack.toString(haxe.CallStack.exceptionStack()), 'error' );
        }
      }
    } else {
      trace( 'No handlers to process msg' );
    }
  }

  private function process_create(client_id : Int, pet_id : String, type : String, data: Dynamic) : Void {
    if( create_handlers[type] != null ) {
      for( func in create_handlers[type] ) {
        try {
          func(client_id, pet_id, data);
        } catch(e:Dynamic) {
          trace('Error executing create handler for ' + pet_id + ': ' + e, 'error');
          trace( haxe.CallStack.toString(haxe.CallStack.exceptionStack()), 'error' );
        }
      }
    } else {
      trace( 'No handlers to process msg' );
    }
  }

  private function process_remove(client_id : Int, pet_id : String, type : String, data: Dynamic) : Void {
    if( remove_handlers[type] != null ) {
      for( func in remove_handlers[type] ) {
        try {
          func(client_id, pet_id, data);
        } catch(e:Dynamic) {
          trace('Error executing create handler for ' + pet_id + ': ' + e, 'error');
          trace( haxe.CallStack.toString(haxe.CallStack.exceptionStack()), 'error' );
        }
      }
    } else {
      trace( 'No handlers to process msg' );
    }
  }

  public inline function register_get_handler( for_type : String, func: Int -> String -> Dynamic -> Void ) : Void {
    if(get_handlers[for_type] != null) get_handlers[for_type].push(func) else get_handlers[for_type] = [func];
  }

  public inline function register_create_handler( for_type : String, func: Int -> String -> Dynamic -> Void ) : Void {
    if(create_handlers[for_type] != null) create_handlers[for_type].push(func) else create_handlers[for_type] = [func];
  }

  public inline function register_remove_handler( for_type : String, func: Int -> String -> Dynamic -> Void ) : Void {
    if(remove_handlers[for_type] != null) remove_handlers[for_type].push(func) else remove_handlers[for_type] = [func];
  }

  public inline function register_join_handler( func: Int -> Void ) : Void {
    join_handlers.push(func);
  }

  public inline function register_left_handler( func: Int -> Void ) : Void {
    left_handlers.push(func);
  }

  public inline function send_privkey( privkey : haxe.io.ArrayBufferView, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'privkey', privkey.buffer, conn);
  }

  public inline function send_token( token : haxe.io.Bytes, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'token', token, conn);
  }

  public inline function send_auth( auth : Bool = true, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'auth', auth, conn);
  }

  public inline function send_post( post : Tpost, client : Int, ?conn : String ) : Void {
    if( post.is_full() ) {
      this.send_response(client, 'full_post', post, conn);
    } else {
      this.send_response(client, 'post', post, conn);
    }
  }

  public inline function send_post_id( id : Tid, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'post_id', id, conn);
  }

  public inline function send_post_removed( removed : Bool = true, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'post_removed', removed, conn);
  }

  public inline function send_sentence( sentence : Tsentence, client : Int, ?conn : String ) : Void {
    if( sentence.is_draft() ) {
      throw 'Only complete sentence can be send to the client';
    } else {
      this.send_response(client, 'sentence', sentence, conn);
    }
  }

  public inline function send_sentence_removed( removed : Bool = true, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'sentence_removed', removed, conn);
  }

  public inline function send_search_result( result : Search_results, client : Int, ?conn : String ) : Void {
    this.send_response(client, 'search_result', result, conn);
  }
}
