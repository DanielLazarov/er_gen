(function (window) {
  'use strict';

  if (typeof window.jQuery === 'undefined') {
    throw new Error('ERDiag\'s JavaScript requires jQuery')
  }

  function ERDiag(settings){
    this.settings = jQuery.extend({}, settings);


    this.makeWidthBinding = function(idx) {
        // These two conversion functions are closed over the IDX variable.
        // This source-to-target conversion extracts a number from the Array at the given index.
        function getColumnWidth(arr) {
          if (Array.isArray(arr) && idx < arr.length) return arr[idx];
          return NaN;
        }
        // This target-to-source conversion sets a number in the Array at the given index.
        function setColumnWidth(w, data) {
          var arr = data.widths;
          if (!arr) arr = [];
          if (idx >= arr.length) {
            for (var i = arr.length; i <= idx; i++) arr[i] = NaN;  // default to NaN
          }
          arr[idx] = w;
          return arr;  // need to return the Array (as the value of data.widths)
        }
        return [
          { column: idx },
          new go.Binding("width", "widths", getColumnWidth).makeTwoWay(setColumnWidth)
        ]
      }

    this.itemTemplate =
      go.GraphObject.make(
        go.Panel, 
        "TableRow",  // this Panel is a row in the containing Table
        new go.Binding("portId", "name"),  // this Panel is a "port"
        { 
          background: "transparent",  // so this port's background can be picked by the mouse
          fromSpot: go.Spot.RightSide,  // links only go from the right side to the left side
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
            fromLinkable: false, toLinkable: false
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
          new go.Binding("text", "info").makeTwoWay()
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
          go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(0)),
          go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(1)),
          go.GraphObject.make(go.RowColumnDefinition, this.makeWidthBinding(2)),
          new go.Binding("itemArray", "fields")
        )  // end Table Panel of items
      )  // end Vertical Panel
    );  // end Node 

    this.linkTemplate = go.GraphObject.make(
      go.Link, { curve: go.Link.Bezier, relinkableFrom: true, relinkableTo: true, toShortLength: 10 },  // let user reconnect links
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
    self.diag.toolManager.mouseDownTools.add(new RowResizingTool());//row resize tool
    self.diag.toolManager.mouseDownTools.add(new ColumnResizingTool());//col resize tool

          // This template represents a whole "record".
    self.diag.nodeTemplate = this.nodeTemplate
    self.diag.linkTemplate = this.linkTemplate

      self.diag.model =
        go.GraphObject.make(go.GraphLinksModel,
          {
            linkFromPortIdProperty: "fromPort",
            linkToPortIdProperty: "toPort",
            // automatically update the model that is shown on this page
            "Changed": function(e) {
              console.log(self.diag.model.toJson());
              //if (e.isTransactionFinished) showModel();
            },
            nodeDataArray: data.nodeDataArray,
            linkDataArray: data.linkDataArray
          });

  };

  ERDiag.prototype.ReLoadDiag = function(data) {
    var self = this;
      self.diag.model =
        go.GraphObject.make(go.GraphLinksModel,
          {
            linkFromPortIdProperty: "fromPort",
            linkToPortIdProperty: "toPort",
            // automatically update the model that is shown on this page
            "Changed": function(e) {
              console.log(self.diag.model.toJson());
              //if (e.isTransactionFinished) showModel();
            },
            nodeDataArray: data.nodeDataArray,
            linkDataArray: data.linkDataArray
          });
  };

     
    window.ERDiag = ERDiag;
})(window);