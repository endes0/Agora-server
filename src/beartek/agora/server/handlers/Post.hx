//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Tpost;
import beartek.agora.types.Tid;
import beartek.agora.types.Types;

@:keep class Post {
  var posts : models.PostsManager = Main.db.posts;

  public function new() {
    Main.connection.register_create_handler('post', this.on_post);
    Main.connection.register_create_handler('edit_post', this.on_edit_post);
    Main.connection.register_get_handler('post', this.on_get_post);
    Main.connection.register_get_handler('full_post', this.on_get_full_post);
  }

  public function get_post( id : Tid, full : Bool = true ) : beartek.agora.types.Post {
    if( id.get().type.getName() != Items_types.Post_item.getName() ) throw 'Invalid Post id';
    var post : beartek.agora.types.Post = haxe.Unserializer.run(posts.get(id.toString()).post);

    if( full ) {
      post.info.id = id.get();
      //TODO: reget author info.
      return post;
    } else {
      post.info = null;
      return post;
    }
  }

  public function get_random( n = 10 ) : Array<beartek.agora.types.Post> {
    var result : Array<beartek.agora.types.Post> = [];
    var posts : Array<models.Posts> = posts.getAll();

    var i : Int = 0;
    while( i <= n && i < posts.length ) {
      try {
        var post : beartek.agora.types.Post = haxe.Unserializer.run(posts[i].post);
        post.info.id = Tid.fromString(posts[i].id).get();
        result.push(post);
      } catch(e:Dynamic) {
        trace('Error getting post ' + i + ': ' + e, 'error');
      }
      i++;
    }

    return result;
  }

  public function create_post( post : Tpost, author : Tid ) : Tid {
    if(author.get().type.getName() != Items_types.User_item.getName()) throw 'Author is not a valid id';
    if(post.is_draft() == false ) this.edit_post(post, author);

    var post_id : Tid = generate_id(author.get());

    post.get().info.author = {id: author.get(), username: null, second_name: null, first_name: null, join_date: null, last_login: null};
    post.get().info.publish_date = datetime.DateTime.now();
    post.get().info.emoji_votes = new Map();

    posts.create(post_id.toString(), haxe.Serializer.run(post.get()));
    trace( 'Post created' );
    return post_id;
  }

  private function generate_id( author : Id ) : Tid {
    return new Tid({ host: author.host, type: Items_types.Post_item, first: author.first, second: generate_char() + generate_char(), third: generate_char() + generate_char()});
  }

  public inline function generate_char() : String {
    return String.fromCharCode(Math.round(Math.random() * 79 + 48));
  }

  public function edit_post( post : Tpost, author : Tid ) : Void {
    if(post.is_draft()) this.create_post(post, author);
    if(post.is_full()) throw 'Invalid post: The post is a full post';
    if(author.get().type.getName() != Items_types.User_item.getName()) throw 'Author is not a valid id';
    if(Tid.equal(author.get(), post.get().info.author.id)) throw 'Authors are differents';

    posts.get(new Tid(post.get().info.id).toString()).set(haxe.Serializer.run(post.get()));
  }

  private function on_get_post( id : Int, conn_id : String, post_id : Id ) : Void {
    Main.connection.send_post(new Tpost(this.get_post(new Tid(post_id), false)), id, conn_id);
  }

  private function on_get_full_post( id : Int, conn_id : String, post_id : Id ) : Void {
    Main.connection.send_post(new Tpost(this.get_post(new Tid(post_id))), id, conn_id);
  }

  private function on_post( id : Int, conn_id : String, post : beartek.agora.types.Post ) : Void {
    var post : Tpost = new Tpost(post);
    var author : Tid = Main.handlers.sessions.sessions[id];

    Main.connection.send_post_id(this.create_post(post, author), id, conn_id);
  }

  private function on_edit_post( id : Int, conn_id : String, post : beartek.agora.types.Post ) : Void {
    var post : Tpost = new Tpost(post);
    var author : Tid = Main.handlers.sessions.sessions[id];

    this.edit_post(post, author);
  }

}
