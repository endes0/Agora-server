package models;

import models.Sentences;

class SentencesManager extends models.autogenerated.SentencesManager
{
  override public function delete(id:String) : Void
    {
      db.query('DELETE FROM `sentences` WHERE `id` = ' + db.quote(id));
    }
}