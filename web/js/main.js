window.CLEANING = {};//Main Cleaning Obj.

//Generic request settings
CLEANING.default_container = '#page-inner-container';
CLEANING.default_err_container = '#err-container';
CLEANING.ajaxRequest = new AjaxRequest({
  dataType : 'html',
  contentType : 'application/x-www-form-urlencoded; charset=UTF-8',
  url : '',
  method : 'POST',
  beforeSend : showLoadingModal,
  complete : hideLoadingModal,
  error : function(jqXHR, textStatus, errorThrown){
    var msg = (textStatus && textStatus != null ? textStatus : 'Connection error');
    var code = (errorThrown && errorThrown != null ? errorThrown : '');
    $(CLEANING.default_err_container).html(generateError(msg, code));
    $(CLEANING.default_err_container).fadeIn('slow')
  },
  processData : true,
  async : true
});

function showLoadingModal(){
  $('#loading-modal').show();
}

function hideLoadingModal(){
  $('#loading-modal').hide();
}

function defaultRequest(params){
  CLEANING.ajaxRequest.sendRequest({
    data : params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(CLEANING.default_err_container).html(data);
        $(CLEANING.default_err_container).fadeIn('slow');
      } else {
        $(CLEANING.default_err_container).html('');
        $(CLEANING.default_container).html(data);
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
      case 'all_clients': allClients(state.params);
        break;
      case 'all_quotes': allQuotes(state.params);
        break;
      case 'home_page_ajax': homePageAjax(state.params);
        break;
      case 'all_teams': allTeams(state.params);
        break;
    }
  }
}



//Event handlers
$(document).on('click', '#brand-btn', function(){
  saveHistoryAndSubmit({method : 'home_page_ajax'});
});
$(document).on('click', '#clients-nav-btn', function(){
  saveHistoryAndSubmit({method : 'all_clients'});
});
$(document).on('click', '#quotes-nav-btn', function(){
  saveHistoryAndSubmit({method : 'all_quotes'});
});
$(document).on('click', '#teams-nav-btn', function(){
  saveHistoryAndSubmit({method : 'all_teams'});
});

$(document).on('click', '#logout-btn', function(){
  $('#logout-form').submit();
});



//Functions
function homePageAjax(){
  defaultRequest({'view' : 'home_page_ajax'});
}

function allClients(){
  defaultRequest({'view' : 'all_clients'});
}

function allQuotes(){
  defaultRequest({'view' : 'all_quotes'});
}

function allTeams(){
  defaultRequest({'view' : 'all_teams'});
}

//CRUD
$(document).on('click', '.crud-create-btn', function(){
  crudCreate($(this));
});
$(document).on('click', '.crud-update-btn', function(){
  crudUpdate($(this));
});
$(document).on('click', '.crud-delete-btn', function(){
  crudDelete($(this));
});
$(document).on('submit', '.crud-form', function(e){
  e.preventDefault();
  crudSubmitCreateOrUpdate($(this));
});
$(document).on('click', '.crud-td-file', function(){
  crudFile($(this));
});

function crudCreate($elem){
  var query_params = {
    view : 'crud_create',
    table : $elem.closest('.crud-table').data('table')
  };

  CLEANING.ajaxRequest.sendRequest({
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(CLEANING.default_err_container).html(data);
        $(CLEANING.default_err_container).fadeIn('slow');
      } else {
        $(CLEANING.default_err_container).html('');
        $('#crud-form-container-' + $elem.closest('.crud-table').data('table')).html(data);
      }
    }
  });
}

function crudSubmitCreateOrUpdate($form)
{
  var query_params = $form.serialize();
  console.log(JSON.stringify(query_params));
  CLEANING.ajaxRequest.sendRequest({
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(CLEANING.default_err_container).html(data);
        $(CLEANING.default_err_container).fadeIn('slow');
      } else {
        $(CLEANING.default_err_container).html('');
        $('#crud-container-' + $form.data('table')).html(data);
      }
    }
  });
}

function crudSubmitUpdate($elem)
{

}

function crudUpdate($elem){
  var query_params = {
    view : 'crud_update',
    table : $elem.closest('.crud-table').data('table'),
    unique_identifier : $elem.closest('tr').data('unique-identifier'),
  };

  CLEANING.ajaxRequest.sendRequest({
    data : query_params,
    success : function(data){
      if(data.indexOf('error-alert') > -1){
        $(CLEANING.default_err_container).html(data);
        $(CLEANING.default_err_container).fadeIn('slow');
      } else {
        $(CLEANING.default_err_container).html('');
        $('#crud-form-container-' + $elem.closest('.crud-table').data('table')).html(data);
      }
    }
  });
}

function crudDelete($elem){
  var query_params = {
    action : 'crud_delete',
    view : 'crud_table',
    table : $elem.closest('.crud-table').data('table'),
    unique_identifier : $elem.closest('tr').data('unique-identifier'),
  };

  var confirmation = confirm("Delete entry?");
  if (confirmation) {
    CLEANING.ajaxRequest.sendRequest({
      data : query_params,
      success : function(data){
        if(data.indexOf('error-alert') > -1){
          $(CLEANING.default_err_container).html(data);
          $(CLEANING.default_err_container).fadeIn('slow');
        } else {
          $(CLEANING.default_err_container).html('');
          $('#crud-container-' + $elem.closest('.crud-table').data('table')).html(data);
        }
      }
    });
  } else {
    return false;
  }
}


function crudFile($elem){
  var $form = $('<form method="POST" action=""><input type="hidden" name="view" value="crud_file"/>  <form><input type="hidden" name="file_path" value="' + $elem.data('filepath') + '"/>  <form><input type="hidden" name="file_type" value="' + $elem.data('filetype') + '"/>  </form>');
  $form.submit();
} 