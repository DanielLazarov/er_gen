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


function crudCreateUpdate($elem){
  var query_params = {
    view : 'home_page_ajax'
  };

  if(typeof $elem !== 'undefined') {
    query_params.diagram_id = $elem.closest('tr').data('unique-identifier');
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
  var query_params = {
    view : 'save_diagram',
    action: 'create_or_update_diagram',
    schema_json : ER.erDiag.diag.model.toJson()
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


//Functions
function homePageAjax(){
  defaultRequest({'view' : 'home_page_ajax'});
}

function allDiagrams(){
  defaultRequest({'view' : 'all_diagrams'});
}



