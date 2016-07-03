window.ER = {};//Main ER Obj.

//Generic request settings
ER.default_container = '#page-inner-container';
ER.default_err_container = '#err-container';
ER.ajaxRequest = new AjaxRequest({
  dataType : 'html',
  contentType : 'application/x-www-form-urlencoded; charset=UTF-8',
  url : '',
  method : 'POST',
  beforeSend : showLoadingModal,
  complete : hideLoadingModal,
  error : function(jqXHR, textStatus, errorThrown){
    var msg = (textStatus && textStatus != null ? textStatus : 'Connection error');
    var code = (errorThrown && errorThrown != null ? errorThrown : '');
    $(ER.default_err_container).html(generateError(msg, code));
    $(ER.default_err_container).fadeIn('slow')
  },
  processData : true,
  async : true
});

console.log(ER.ajaxRequest);

function showLoadingModal(){
  $('#loading-modal').show();
}

function hideLoadingModal(){
  $('#loading-modal').hide();
}

function defaultRequest(params){
  console.log(ER);

  ER.ajaxRequest.sendRequest({
    data : params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(ER.default_err_container).html(data);
        $(ER.default_err_container).fadeIn('slow');
      } else {
        $(ER.default_err_container).html('');
        $(ER.default_container).html(data);
      }
    }
  });
}

//Save home page state 
(function(){

  console.log(history.length);
  //
  window.onpopstate = function(event) {
    console.log(history.length);
    console.log(JSON.stringify(event.state));
    if(event.state != null){
      submitRequestState(event.state);
    }
  };
  console.log('replaced');
  history.replaceState({method : 'home_page_ajax'}, '');

})();


//Client messages
function generateSuccess(msg){
  msg = typeof msg !== 'undefined' ? msg : 'Success';
  return '<div id="success-alert" class="alert alert-success col-sm-12"> ' + msg + '</div>';
}

function generateInfo(msg){
  msg = typeof msg !== 'undefined' ? msg : 'Info';
  return '<div id="info-alert" class="alert alert-info col-sm-12"> ' + msg + '</div>';
}

function generateWarning(msg){
  msg = typeof msg !== 'undefined' ? msg : 'Warning';
  return '<div id="warning-alert" class="alert alert-warning col-sm-12"> ' + msg + '</div>';
}

function generateError(msg, code){
  msg = typeof msg !== 'undefined' ? msg : 'Error';
  code = typeof code !== 'undefined' ? code : '';
  return '<div id="error-alert" class="alert alert-danger col-sm-12"> ' + msg + ' <b> ' + code + ' </b></div>';
}

//History management
function saveHistoryAndSubmit(state){
  if(state != null){
    history.pushState(state, '');
  }
  submitRequestState(state);
}

function submitRequestState(state){
  if(state != null){
    switch(state.method){
      case 'all_diagrams': allDiagrams(state.params);
        break;
      case 'home_page_ajax': homePageAjax(state.params);
        break;
    }
  }
}


//Event handlers
$(document).on('click', '#diagrams-nav-btn', function(){
  saveHistoryAndSubmit({method : 'all_diagrams'});
});
$(document).on('click', '#brand-btn', function(){
  saveHistoryAndSubmit({method : 'home_page_ajax'});
});
$(document).on('click', '#logout-btn', function(){
  $('#logout-form').submit();
});

$(document).on('click', '.crud-create-btn', function(){
  crudCreateUpdate(undefined);
});
$(document).on('click', '.crud-update-btn', function(){
  crudCreateUpdate($(this));
});
$(document).on('click', '.crud-delete-btn', function(){
  crudDelete($(this));
});

$(document).on('click', '#save-btn', function(){
  submitCreateUpdate(false);
});

$(document).on('click', '#submit-add-table-btn', function(){
  var name = $('#add-table-name-input').val();

  if( ! name) {
    $('#add-table-name-input').addClass('input-error');
    return false;
  } else {
    $('#add-table-name-input').removeClass('input-error');
    $('#add-table-modal').modal('toggle');
    ER.erDiag.AddNode(name);
  }
});

$(document).on('click', '#remove-table-btn', function(){
  $('#remove-table-name-holder').html(ER.erDiag.selection.data.key);
});
$(document).on('click', '#submit-remove-table-btn', function(){
  ER.erDiag.RemoveNode(ER.erDiag.selection);
});

$(document).on('click', '#remove-column-btn', function(){
  $('#remove-column-table-name-holder').html(ER.erDiag.selection.data.key);
});
$(document).on('click', '#submit-remove-column-btn', function(){
  var name = $('#remove-column-name-input').val();

  if( ! name) {
    $('#remove-column-name-input').addClass('input-error');
    return false;
  } else if( ! ER.erDiag.RemoveColumn(ER.erDiag.selection, name)) {
    $('#remove-column-name-input').addClass('input-error');
    $('#remove-column-err').show();
    return false;
  } else {
    $('#remove-column-err').hide();
    $('#remove-column-name-input').removeClass('input-error');
    $('#remove-column-modal').modal('toggle');
    ER.erDiag.RemoveColumn(ER.erDiag.selection, name);
  }
});

$(document).on('click', '#add-column-btn', function(){
  $('#add-column-table-name-holder').html(ER.erDiag.selection.data.key);
});

$(document).on('click', '#submit-add-column-btn', function(){
  
  var name = $('#add-column-name-input').val();
  if( ! name) {
    $('#add-column-name-input').addClass('input-error');
    return false;
  } 
  var col_info = {
    name : name,
    type : $('#add-column-type-select').val(),
    "default" : $('#add-column-default-input').val()
  };

  var constraints = new Array();
  if($('#add-column-constr-u').is(':checked')) {
    constraints.push("U"); 
  }
  if($('#add-column-constr-nn').is(':checked')) {
    constraints.push("NN"); 
  }
  col_info.constr = constraints.join(', ');

  if($('#add-column-key-type-none').is(':checked')){
    console.log('None checked');
    col_info.figure = "LineH";
    col_info.color = "#7FBA00";
  } else if($('#add-column-key-type-pk').is(':checked')) {
    col_info.figure = "Ellipse";
    col_info.color = "#F25022";
  } else if($('#add-column-key-type-fk').is(':checked')) {
    col_info.figure = "TriangleUp";
    col_info.color = "#225cf2";
  }

  $('#add-column-name-input').removeClass('input-error');
  ER.erDiag.AddColumn(ER.erDiag.selection, col_info);
  $('#add-column-modal').modal('toggle'); 
});


$(document).on('click', '#submit-import-from-ddl-btn', function(){
  var ddl = $('#import-from-ddl-input').val();
  if( ! ddl) {
    $('#import-from-ddl-input').addClass('input-error');
    return false;
  }

  $('#import-from-ddl-input').removeClass('input-error');
  $('#import-from-ddl-modal').modal('toggle');
  submitCreateFromDDL(ddl);
});









function crudCreateUpdate($elem){
  var query_params = {
    view : 'home_page_ajax'
  };

  if(typeof $elem !== 'undefined') {
    query_params.diagram_id = $elem.closest('tr').data('unique-identifier');
  } else {
    query_params.new_diagram = 1;
  }

  ER.ajaxRequest.sendRequest({
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(ER.default_err_container).html(data);
        $(ER.default_err_container).fadeIn('slow');
      } else {
        $(ER.default_err_container).html('');
        $(ER.default_container).html(data);
      }
    }
  });
}

function submitCreateUpdate(silent){

  var schema_json = JSON.parse(ER.erDiag.diag.model.toJson());
  for(var i = 0; i < schema_json.nodeDataArray.length; i++){
    schema_json.nodeDataArray[i].fields.splice(0, 1);
  }

  var query_params = {
    view : 'save_diagram',
    action: 'create_or_update_diagram',
    schema_json : JSON.stringify(schema_json),
    diagram_name : $('#diagram-name').val()

  };

  if($('#save-btn').data('diagram-id')) {
    query_params.diagram_id = $('#save-btn').data('diagram-id');
  }

  var req_settings = {
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(ER.default_err_container).html(data);
        $(ER.default_err_container).fadeIn('slow');
      } else {
        $(ER.default_err_container).html(data);
        $(ER.default_err_container).fadeIn('slow');
      }
    }
  }
  if(silent)
  {
    req_settings.error = function(){};
  }

  ER.ajaxRequest.sendRequest(req_settings);

}

function crudDelete($elem){
  var query_params = {
    action : 'delete_diagram',
    view : 'all_diagrams',
    diagram_id : $elem.closest('tr').data('unique-identifier'),
  };

  var confirmation = confirm('Delete diagram ' + '"' + $elem.closest('tr').data('name') + '"?');
  if (confirmation) {
    ER.ajaxRequest.sendRequest({
      data : query_params,
      success : function(data){
        if(data.indexOf('error-alert') > -1){
          $(ER.default_err_container).html(data);
          $(ER.default_err_container).fadeIn('slow');
        } else {
          $(ER.default_err_container).html('');
          $(ER.default_container).html(data);
        }
      }
    });
  } else {
    return false;
  }
}

function submitCreateFromDDL(ddl){
  var query_params = {
    view : 'home_page_ajax',
    action: 'create_or_update_diagram',
    diagram_name : $('#diagram-name').val(),
    ddl : ddl,
    dialect : $('#import-from-ddl-dialect').val()
  };

  ER.ajaxRequest.sendRequest({
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(ER.default_err_container).html(data);
        $(ER.default_err_container).fadeIn('slow');
      } else {
        $(ER.default_err_container).html('');
        $(ER.default_container).html(data);
      }
    }
  });

}

function downloadCanvas() {
  
  $('#save-as-image-download-btn').hide();
  $('#save-as-image-loading').show();
  var canvas_div = document.querySelector('#canvas-container div div');
  var canvas = document.querySelector('#canvas-container canvas');
  

  var patt = new RegExp("[0-9]*");
  var calc_height = +patt.exec(canvas_div.style.height)[0]; //+ is for convertion to number
  var calc_width = +patt.exec(canvas_div.style.width)[0];

  var real_height = (calc_height > canvas.height) ? calc_height : canvas.height;
  var real_width = (calc_width > canvas.width) ? calc_width : canvas.width;

  var new_canvas_div = document.querySelector('#save-as-image-canvas-container');
  new_canvas_div.style.height = real_height + 'px';
  new_canvas_div.style.width = real_width + 'px';

  ER.erDiagShad.ReLoadDiag(JSON.parse(ER.erDiag.diag.model.toJson()));

  setTimeout(function(){
    $('#save-as-image-loading').hide();
        var new_canvas = document.querySelector('#canvas-container-shad canvas');
        var link = document.getElementById('save-as-image-download-btn');
        link.href = new_canvas.toDataURL("image/png");
        link.download = $('#diagram-name').val();
        $('#save-as-image-download-btn').show();
  }, 2000);

  
}


$(document).on('click', '#download-btn', function(){
  downloadCanvas();
});


//Functions
function homePageAjax(){
  defaultRequest({'view' : 'home_page_ajax'});
}

function allDiagrams(){
  defaultRequest({'view' : 'all_diagrams'});
}



