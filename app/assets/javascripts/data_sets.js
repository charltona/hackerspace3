// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$( document ).on('turbolinks:load', function() {
  if(!$('[id$="wrapper"]').length) {
    $('#dataset_table').DataTable({
      stateSave: true
    });
  }
});
