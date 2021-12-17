// 'transcript' variable defined elsewhere
// it is an array of [seconds, caption] pairs

var comp = app.project.activeItem;


// Delete existing "Generated Captions" text layer
for (var i = 1; i <= comp.numLayers; i++) {
    if (comp.layer(i).name == "Generated Captions") {
        comp.layer(i).remove();
    }
}

// Create new "Generated Captions" text layer
var captionLayer = comp.layers.addText("Generated Captions");
captionLayer.name = "Generated Captions";

// Start with no captions
captionLayer.sourceText.setValueAtTime(0, "");

// Set captions from transcript variable
for (var i = 0; i < transcript.length; i++) {
    var time = transcript[i][0];
    var text = transcript[i][1];
    captionLayer.sourceText.setValueAtTime(time, text);
};
