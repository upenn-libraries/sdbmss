var t;

$(document).ready( function (e) {
  
  function noButtons () {
    return "<div class='popover tour'>" +
      "<div class='arrow'></div>" +
      "<h3 class='popover-title'></h3>" +
      "<div class='popover-content'></div>" +
      "<div class='popover-navigation'>" +
        "<button class='btn btn-default' data-role='prev'>« Prev</button>" +
        "<button class='btn btn-default' data-role='end'>End tour</button>" +
      "</div>" +
    "</div>"
  }

  function matchValue (tour) {
    $(this.element).focus();
    if ($(this.element).val() != this.value) {
      var t = this;
      setTimeout( function () { t.onShown(tour); }, 500);
    } else {
      tour.next();
    }
  }

  var tour = new Tour({
    backdropPadding: 10,
    keyboard: false,
    steps: [
    {
      element: "#dashboard-add-new-entry",
      title: "Click 'Add New Entry'",
      content: "To add a new entry, click this link on the Dashboard page",
      path: "/dashboard",
      reflex: true,
      backdrop: true
    },
    {
      element: ".find-source-container",
      title: "Find a Source",
      content: "First you need to identify the Source for the evidence you are creating.<br>This is the <a target='_blank' href='http://www.textmanuscripts.com/medieval/paschasius-radbertus-medieval-manuscript-87606?inventorySearch=1&p=1'>Sample Source</a> we will be using.",
      placement: "auto top",
      path: "/entries/new",
      backdrop: true
    },
    {
      element: ".find-source-container input[name=date]",
      title: "Enter the date",
      content: "Fill in the year 2012",
      template: noButtons,
      value: "2012",
      onShown: matchValue
    },
    {
      element: ".find-source-container input[name=agent]",
      title: "Enter the name of the source agent",
      content: "Fill in the name 'Sotheby'",
      template: noButtons,
      value: "Sotheby",
      onShown: matchValue
    },
    {
      element: ".first-source",
      title: "Select an existing Source",
      content: "Click here to add an Entry for this Source.",
      backdrop: true,
      template: noButtons,
      reflex: true
    },
    {
      element: "",
      title: "Adding an Entry",
      content: "Now you are ready to add an entry for this Source.",
      backdrop: true,
      orphan: true
    },
    {
      element: "",
      title: "Adding an Entry",
      content: "An Entry contains a snapshot of information about a Manuscript.  Follow along as we enter data from our <a target='_blank' href='http://www.textmanuscripts.com/medieval/paschasius-radbertus-medieval-manuscript-87606?inventorySearch=1&p=1'>Sample Source</a>.",
      backdrop: true,
      orphan: true
    },
    {
      element: "#cat_lot_no",
      title: "Catalog or Lot Number",
      content: "Enter the catalog or lot number.  In this case, it is 822.",
      value: "822",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "",
      title: "Adding descriptive information",
      content: "Add as much descriptive information as possible in the following fields.",
      backdrop: true,
      orphan: true,
      placement: 'bottom'
    },
    {
      element: "#add_title",
      title: "Add Title",
      content: "Click here to add a new Title field.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#title_0",
      title: "Title As Recorded",
      content: "Enter the title as it is literally recorded, as close as possible.  In this case, enter <b>De corpore et sanguine domini</b>",
      value: "De corpore et sanguine domini",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#common_title_0",
      title: "Common Title",
      content: "You can also enter a general or alternate name, if it is appropriate.  In this case, enter <b>On the Body and Blood of the Lord</b>",
      value: "On the Body and Blood of the Lord",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#author_observed_name_0",
      title: "Author As Recorded",
      content: "Now let's enter the information we have about the Author.  In the 'As Recorded' field, fill in <b>Pascasius Radbertus</b>",
      value: "Pascasius Radbertus",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#find_author_name_authority_0",
      title: "Find Author in Name Authority",
      content: "Click on this button to search for the Author in the SDBM Name Authority.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "",
      orphan: true,
      title: "The Name Authority",
      content: "The Name Authority is a common list of Names to help in searching and common identification.",
      backdrop: true,
      placement: 'bottom'
    },
    {
      element: "#searchNameAuthority",
      title: "Search for the Author",
      content: "Do a search for the author you have recorded.  Enter <b>Radbertus</b> in the search field.",
      value: "Radbertus",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#selectNameButton",
      title: "Confirm your selection",
      content: "Once you have found the Name you are looking for, click to confirm adding it.",
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#add_date",
      title: "Add Date",
      content: "Click here to add a new Date field.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#date_observed_date_0",
      title: "Enter the Date as observed",
      content: "Enter the Date as it appears in the Source, as appropriate.  Here, enter the date <b>c. 1120 to 1140</b>",
      value: "c. 1120 to 1140",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#date_normalized_start_0",
      title: "Date Range",
      content: "Depending on the format of the observed Date, sometimes we can automatically create a Date range for the given value.<br>However, it may not match the range you have in mind.  Change the start date to <b>1120</b>.",
      value: "1120",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#add_language",
      title: "Add Language",
      content: "Click here to add a new Language field.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#find_language_name_authority_0",
      title: "Find Language in Name Authority",
      content: "Click on this button to search for the Language in the SDBM Name Authority.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#searchModelAuthority",
      title: "Search for the Language",
      content: "Do a search for the language described in the Source.  Enter <b>Latin</b> in the search field.",
      value: "Latin",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#selectModelButton",
      title: "Confirm your selection",
      content: "Once you have found the Name you are looking for, click to confirm adding it.",
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#add_material",
      title: "Add Material",
      content: "Click here to add a new Material field.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#material_0",
      title: "Choose the Correct Material",
      content: "Select the appropriate material (<b>Papyrus</b>) from the dropdown menu.",
      value: "Papyrus",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#add_place",
      title: "Add Place",
      content: "Click here to add a new Place field.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#place_observed_name_0",
      title: "Place Information",
      content: "Enter the recorded place or location of the manuscript.  Fill in the entire content of <b>Southern Europe (Southern Italy or France?)</b>",
      value: "Southern Europe (Southern Italy or France?)",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#find_place_name_authority_0",
      title: "Find Place in Name Authority",
      content: "Click on this button to search for the Place in the SDBM Name Authority.",
      backdrop: true,
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#searchModelAuthority",
      title: "Search for the Place",
      content: "Do a search for the Place described in the Source.  Enter <b>Southern Europe</b> in the search field.",
      value: "Southern Europe",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "#selectModelButton",
      title: "Confirm your selection",
      content: "Once you have found the Name you are looking for, click to confirm adding it.",
      reflex: true,
      template: noButtons,
      placement: 'bottom'
    },
    {
      element: "#folios",
      title: "Enter the number of Folios",
      content: "There are numerous numeric fields you can enter about a Manuscript.  For now, just enter the number of Folios (<b>148</b>).",
      value: "148",
      template: noButtons,
      onShown: matchValue,
      placement: 'bottom'
    },
    {
      element: "",
      title: "Well done!",
      content: "Thank you for going through the tutorial.",
      backdrop: true,
      orphan: true
    }
  ]});

  tour.init();
  //tour.start();

  t = tour;

});