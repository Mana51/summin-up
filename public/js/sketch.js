function setup() {
  createCanvas(windowWidth / 2, windowHeight - 150);
  background(0);
  noStroke();
  x = mouseX;
}

function draw() {
  fill(237, 230, 173);
  if (mouseX > pmouseX) {
    if (mouseIsPressed) {
      ellipse (mouseX, mouseY, 20); 
    }
  }
  else if (mouseX < pmouseX) {
    erase();
    if (mouseIsPressed) {
      ellipse (mouseX, mouseY, 24); 
    }
    noErase() ;
  }
}