(function() {
  CKEDITOR.config.filebrowserImageUploadUrl = '/admin/_upload';

  $('textarea').each(function() {
    CKEDITOR.replace(this.id);
  });

}).call(this);
