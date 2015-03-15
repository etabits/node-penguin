(function() {
  CKEDITOR.config.filebrowserImageUploadUrl = '/admin/_upload';

  $('textarea').each(function() {
    if ($(this).hasClass('field-widget-mixed-control')) {
      // don't instantiate CKEDITOR for textareas with above className
      return;
    }
    CKEDITOR.replace(this.id);
  });

}).call(this);
