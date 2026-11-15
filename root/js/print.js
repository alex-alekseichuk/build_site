function file_ext(fname) {
	var i = fname.lastIndexOf('.');
	if (-1 == i)
		return '';
	return fname.substring(i + 1);
}

function print_me() {
  var file_id = document.getElementById('file_id').value;


  // check that our ActiveX stuff exists
  if (!factory.object || !secmgr.object) {
    $.bs.notice("The required components have not been installed for printing. Please refer to the help for more details.");
    return;
  }


  window.status = "Sending Documents to Printer...";

/*
  // show them what we are doing
  if (true) {
    var width = 220;
    var height = 220;

    idWait = document.getElementById('idWait');

    idWait.style.pixelWidth = width;
    idWait.style.pixelHeight = height;

    idWait.style.pixelLeft = document.body.scrollLeft + width;
    idWait.style.pixelTop = document.body.scrollTop + height/2;
    idWait.style.visibility = "visible";
  }
*/

  // get the urls
  var arr = accumulate_checked(0);

  // disable header and footer for html
  factory.printing.header = "";
  factory.printing.footer = "";


  // do the printing
  for (var j = 0; j < arr.length; j++) {
	  var url = arr[j].name;
	  var ext = arr[j].type;
      if (!url) continue;
      if (ext == 'html' || ext == 'htm' || ext == 'jpeg' || ext == 'jpg' || ext == 'gif' || ext == 'png' || ext == 'tif' || ext == 'tiff' || ext == 'xml') {
        factory.printing.PrintHTML(url);
      } else if (ext == 'pdf' || ext == 'word' || ext == 'excel' || ext == 'doc' || ext == 'xls' || ext == 'rtf' || ext == 'text' || ext == 'txt' || ext == 'csv') {
        factory.printing.BatchPrintPDF(url);
      }
  }


  // do the redirect
  if (factory.printing.WaitForSpoolingComplete()) {
    window.status = "";
    //idWait.style.visibility = "hidden";
    $.bs.notice( "Your selected document(s) have been sent to the printer." );
  }


}

// handle chosen action
function select_action(act) {
    if (act.match(/print/i)) {
        print_me();
    } else if (act.match(/delete/i) || act.match(/remove/i)) {
        delete_me();
    } else {
        return true;
    }
    return false;
}

// return an array with undef for unchecked ones.
// array values can be names or values
// does it in reverse order
function accumulate_checked(as_names) {
    var arr = [];
    var n = 0;
    $('tr', 'table#tablePrintItems').each(function(){
        var checkbox = $('input.print-checkbox', this);
        if (checkbox && checkbox.is(':checked')) {
            arr[n++] = {name: (as_names ? name : checkbox.val()), type: checkbox.attr('file_type')};
        }
    });
    return arr;
}

// ensure that there is an action and that some are checked.
function printPackage() {
    var checked_count = 0;
    $('tr', 'table#tablePrintItems').each(function(n){
        var checkbox = $('input.print-checkbox', this);
        if (checkbox && checkbox.is(':checked'))
            checked_count++;
    });
    if(checked_count == 0) {
      alert("Please select documents before submitting!");
      return false;
    }
    else {
      return select_action("print");
    }
}

