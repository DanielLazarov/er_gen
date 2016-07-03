(function (window) {
  'use strict';

  if (typeof window.jQuery === 'undefined') {
    throw new Error('ERDiag\'s JavaScript requires jQuery')
  }

  function ERDiag(settings){
    this.settings = jQuery.extend({}, settings);

    this.itemTemplate =
      go.GraphObject.make(
        go.Panel, 
        "TableRow",  // this Panel is a row in the containing Table
        new go.Binding("portId", "name"),  // this Panel is a "port"
        { 
          background: "transparent",  // so this port's background can be picked by the mouse
          fromSpot: go.Spot.LeftSide,  // links only go from the right side to the left side
          toSpot: go.Spot.LeftSide,
          // allow drawing links from or to this port:
          fromLinkable: true, toLinkable: true 
        },
        go.GraphObject.make(go.Shape,
          {
            column: 0,
            width: 10, height: 10, margin: 2,
            // but disallow drawing links from or to this shape:
            fromLinkable: false, toLinkable: false
          },
        new go.Binding("figure", "figure"),
        new go.Binding("fill", "color")),
        go.GraphObject.make(go.TextBlock,
          {
            column: 1,
            margin: new go.Margin(0, 2),
            stretch: go.GraphObject.Horizontal,
            font: "bold 13px sans-serif",
            wrap: go.TextBlock.None,
            overflow: go.TextBlock.OverflowEllipsis, 
            // and disallow drawing links from or to this text:
            fromLinkable: true, toLinkable: true,
            editable: true
          },
          new go.Binding("text", "name")
        ),
        go.GraphObject.make(go.TextBlock,
          {
            column: 2,
            margin: new go.Margin(0, 2),
            stretch: go.GraphObject.Horizontal,
            font: "13px sans-serif",
            maxLines: 3,
            overflow: go.TextBlock.OverflowEllipsis,
            editable: true
          },
          new go.Binding("text", "type").makeTwoWay()
        ),
        go.GraphObject.make(go.TextBlock,
          {
            column: 3,
            margin: new go.Margin(0, 2),
            stretch: go.GraphObject.Horizontal,
            font: "13px sans-serif",
            maxLines: 3,
            overflow: go.TextBlock.OverflowEllipsis,
            editable: true
          },
          new go.Binding("text", "constr").makeTwoWay()
        ),
        go.GraphObject.make(go.TextBlock,
          {
            column: 4,
            margin: new go.Margin(0, 2),
            stretch: go.GraphObject.Horizontal,
            font: "13px sans-serif",
            maxLines: 3,
            overflow: go.TextBlock.OverflowEllipsis,
            editable: true
          },
          new go.Binding("text", "default").makeTwoWay()
        )
     );

    this.nodeTemplate = go.GraphObject.make(
        go.Node, "Auto",
        new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify),
        // this rectangular shape surrounds the content of the node
        //Node fill.
        go.GraphObject.make(go.Shape,{ fill: "#EEEEEE" }),
        // the content consists of a header and a list of items
        go.GraphObject.make(go.Panel, "Vertical", { stretch: go.GraphObject.Horizontal, alignment: go.Spot.TopLeft },
        // this is the header for the whole node
        //Node header
        go.GraphObject.make(
          go.Panel, "Auto", { stretch: go.GraphObject.Horizontal },  // as wide as the whole node
          go.GraphObject.make(go.Shape, { fill: "#1570A6", stroke: null }),
          go.GraphObject.make(go.TextBlock, 
                                { 
                                  alignment: go.Spot.Center, 
                                  margin: 3, 
                                  stroke: "white", 
                                  textAlign: "center", 
                                  font: "bold 12pt sans-serif"
                                }, new go.Binding("text", "key")
          )
        ),
          // this Panel holds a Panel for each item object in the itemArray;
          // each item Panel is defined by the itemTemplate to be a TableRow in this Table
        go.GraphObject.make(go.Panel, "Table",
          {
            name: "TABLE", stretch: go.GraphObject.Horizontal,
            minSize: new go.Size(100, 10),
            defaultAlignment: go.Spot.Left,
            defaultStretch: go.GraphObject.Horizontal,
            defaultColumnSeparatorStroke: "gray",
            defaultRowSeparatorStroke: "gray",
            itemTemplate: this.itemTemplate
          },
          //go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(0)),
          //go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(1)),
          //go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(2)),
          go.GraphObject.make(go.RowColumnDefinition, { row: 1, separatorStrokeWidth: 1.5, separatorStroke: "black" }),//Draw dark lines
          go.GraphObject.make(go.RowColumnDefinition, { column: 1, separatorStrokeWidth: 1.5, separatorStroke: "black" }),
          go.GraphObject.make(go.RowColumnDefinition, { column: 2, separatorStrokeWidth: 1.5, separatorStroke: "black" }),
          go.GraphObject.make(go.RowColumnDefinition, { column: 3, separatorStrokeWidth: 1.5, separatorStroke: "black" }),
          go.GraphObject.make(go.RowColumnDefinition, { column: 4, separatorStrokeWidth: 1.5, separatorStroke: "black" }),
          new go.Binding("itemArray", "fields")
        )  // end Table Panel of items
      )  // end Vertical Panel
    );  // end Node 

    this.linkTemplate = go.GraphObject.make(
      go.Link, { relinkableFrom: true, relinkableTo: true, routing: go.Link.AvoidsNodes},  // let user reconnect links
      go.GraphObject.make(go.Shape, { strokeWidth: 1.5 }),
      go.GraphObject.make(go.Shape, { toArrow: "Standard", stroke: null })
    );    
  }

  ERDiag.prototype.LoadDiag = function(container_id, data) {
    var self = this;
    self.diag = go.GraphObject.make(go.Diagram, container_id,{
                  initialContentAlignment: go.Spot.Center,//set items in center if no position is specified
                  initialAutoScale: go.Diagram.Uniform,//Auto scale (zoom to fit)
                  validCycle: go.Diagram.CycleAll,  //allow loops
                  "undoManager.isEnabled": false //dont allow history manager for now
    });
    //self.diag.toolManager.mouseDownTools.add(new RowResizingTool());//row resize tool
    //self.diag.toolManager.mouseDownTools.add(new ColumnResizingTool());//col resize tool

          // This template represents a whole "record".
    self.diag.nodeTemplate = this.nodeTemplate
    self.diag.linkTemplate = this.linkTemplate

    for(var i = 0; i < data.nodeDataArray.length; i++) {
      data.nodeDataArray[i].fields.unshift({"info": "",
        "name": "Name",
        "color": "#F25022",
        "figure": "AsteriskLine",
        "constr": "Constr",
        "type" : "Type",
        "default" : "Default"});
    }

    self.diag.model =
      go.GraphObject.make(go.GraphLinksModel,
        {
          linkFromPortIdProperty: "fromPort",
          linkToPortIdProperty: "toPort",
          // automatically update the model that is shown on this page
          "Changed": function(e) {
            //console.log(self.diag.model.toJson());
            //if (e.isTransactionFinished) showModel();
          },
          nodeDataArray: data.nodeDataArray,
          linkDataArray: data.linkDataArray
        }
    );

    self.diag.addDiagramListener('ChangedSelection', function(){
        self.selection = self.diag.selection.first();
     });

  };

  ERDiag.prototype.ReLoadDiag = function(data) {
    var self = this;

    // for(var i = 0; i < data.nodeDataArray.length; i++) {
    //   data.nodeDataArray[i].fields.unshift({"info": "",
    //     "name": "Name",
    //     "color": "#F25022",
    //     "figure": "AsteriskLine",
    //     "constr": "Constr",
    //     "type" : "Type",
    //     "default" : "Default"});
    // }

    self.diag.model =
      go.GraphObject.make(go.GraphLinksModel,
        {
          linkFromPortIdProperty: "fromPort",
          linkToPortIdProperty: "toPort",
          // automatically update the model that is shown on this page
          "Changed": function(e) {
            //console.log(self.diag.model.toJson());
            //if (e.isTransactionFinished) showModel();
          },
          nodeDataArray: data.nodeDataArray,
          linkDataArray: data.linkDataArray
        });
  };

  ERDiag.prototype.AddNode = function(name) {
    var self = this;

    self.diag.startTransaction("addNode");
    self.diag.model.addNodeData({
      "key": name,
      "loc": "0 0",
      "fields": [
        {
          "info": "",
          "name": "Name",
          "color": "#F25022",
          "figure": "AsteriskLine",
          "constr": "Constr",
          "type" : "Type",
          "default" : "Default"
        }
      ],
    });
    self.diag.commitTransaction("addNode");
  };

  ERDiag.prototype.RemoveNode = function(node) {
    var self = this;

    self.diag.startTransaction("removeNode");
    self.diag.model.removeNodeData(node.data);
    self.diag.commitTransaction("removeNode");
  };

  ERDiag.prototype.AddColumn = function(node, column_data) {
    var self = this;

    if (node === null) return;

    self.diag.startTransaction("addColumn");
    self.diag.model.addArrayItem(node.data.fields, column_data);
    self.diag.commitTransaction("addColumn");
  };

  ERDiag.prototype.RemoveColumn = function(node, column_name) {
    var self = this;
    
    if (node === null) return;

    for(var i = 1; i < node.data.fields.length; i++)
    {
      if(node.data.fields[i].name === column_name){
        self.diag.startTransaction("removeColumn");
        self.diag.model.removeArrayItem(node.data.fields, i);
        self.diag.commitTransaction("removeColumn");
        return true;
      }
    }
    
    return false;
  };

     
    window.ERDiag = ERDiag;
})(window);