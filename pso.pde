import java.util.Random;
import controlP5.*;

class Particle
{
  public double[] velocity = new double[2];
  public double[] position = new double[2];
  public double[] previousPosition = new double[2];
  public double[] bestPosition = new double[2];
}

class Problem
{
  public final double xMin = -1.5, xMax = 4.0;
  public final double yMin = -3.0, yMax = 4.0;

  public double[] bestPosition = new double[2];
  public double minimalFunctionValue = Double.MAX_VALUE;

  public double calcultateFunctionValue(double x, double y)
  {
    return Math.sin(x + y) + Math.pow(x - y, 2.0) - 1.5 * x + 2.5 * y + 1.0;
  }
}

Problem problem;
Particle[] particles;
int particleCount;
int iterationCount = 100;
int currentIteration = 0;
float omega = 0.9, omegaDecay = 0.00007, C1 = 0.5, C2 = 0.3;
String positionResetStrategy = "Border";
String velocityResetStrategy = "Keep current";

ControlFrame cf;
boolean pause = true;
int iterationsPerSecond = 1;

PFont font;
void settings()
{
  size(1600, 900, P2D);
}

void setup()
{
  colorMode(HSB, 360, 100, 100);
  noStroke();
  frameRate(60);
  
  font = createFont("Verdana Bold", 15);
  textFont(font);
  
  cf = new ControlFrame(this);

  reset();
}

void draw()
{
  background(0);
  drawCoordinateGrid();
  drawParticles();

  textSize(20);
  if (currentIteration == iterationCount)
    fill(0, 100, 100);
  else fill(255);
  textAlign(TOP, RIGHT);
  text("Iteration: " + currentIteration + ", omega: " + omega + ", C1: " + C1 + ", C2: " + C2, 20, 20);
  text("Best solution: f(" + problem.bestPosition[0] + ", " + problem.bestPosition[1] + ") = " + problem.minimalFunctionValue, 20, 40);

  if (pause)
  {
    return;
  }

  if (currentIteration >= iterationCount)
  {
    return;
  }

  runIteartionPSO();

  currentIteration++;
  delay(1000 / iterationsPerSecond);
}

void runIteartionPSO()
{
  for (int i = 0; i < particleCount; i++)
  {
    double[] R1 = new double[]{randomDouble(0.0, 1.0, false), randomDouble(0.0, 1.0, false)};
    double[] R2 = new double[]{randomDouble(0.0, 1.0, false), randomDouble(0.0, 1.0, false)};

    for (int d = 0; d < 2; d++)
    {
      particles[i].previousPosition[d] = particles[i].position[d];
      particles[i].velocity[d] =  omega * particles[i].velocity[d] +
        C1*R1[d] * (particles[i].bestPosition[d] - particles[i].position[d]) +
        C2*R2[d] * (problem.bestPosition[d] - particles[i].position[d]);

      particles[i].position[d] = particles[i].position[d] + particles[i].velocity[d];
    }

    if (particles[i].position[0] < problem.xMin || particles[i].position[0] > problem.xMax)
    {
      double[] newPositionVelocity = resetParticle(particles[i].position[0], particles[i].velocity[0], problem.xMin, problem.xMax);
      particles[i].position[0] = newPositionVelocity[0];
      particles[i].velocity[0] = newPositionVelocity[1];
    }

    if (particles[i].position[1] < problem.yMin || particles[i].position[1] > problem.yMax)
    {
      double[] newPositionVelocity = resetParticle(particles[i].position[1], particles[i].velocity[1], problem.yMin, problem.yMax);
      particles[i].position[1] = newPositionVelocity[0];
      particles[i].velocity[1] = newPositionVelocity[1];
    }

    updateGlobalBestValue(particles[i]);
    updatePersonalBestValue(particles[i]);
  }

  omega -= omegaDecay;
}

void updateGlobalBestValue(Particle p)
{
  double x = p.position[0], y = p.position[1];
  double functionValue = problem.calcultateFunctionValue(x, y);

  if (functionValue < problem.minimalFunctionValue)
  {
    problem.minimalFunctionValue = functionValue;
    problem.bestPosition[0] = x;
    problem.bestPosition[1] = y;
  }
}

void updatePersonalBestValue(Particle p)
{
  double x = p.position[0], y = p.position[1];
  double xpb = p.bestPosition[0], ypb = p.bestPosition[1];
  double functionValue = problem.calcultateFunctionValue(x, y);
  double pbFunctionValue = problem.calcultateFunctionValue(xpb, ypb);

  if (functionValue < pbFunctionValue)
  {
    p.bestPosition[0] = x;
    p.bestPosition[1] = y;
  }
}


double[] resetParticle(double position, double velocity, double min, double max)
{
  double newPosition = 0, newVelocity = 0;
  double d = position < min ? min - position : position - max;

  switch(positionResetStrategy)
  {
  case "Border":
    newPosition = position < min ? min : max;
    break;
  case "Random":
    newPosition = randomDouble(min, max, true);
    break;
  case "Reflect":
    newPosition = position < min ? min + d : max - d;
    break;
  default:
    break;
  }
  switch(velocityResetStrategy)
  {
  case "Keep current":
    newVelocity = velocity;
    break;
  case "Set to zero":
    newVelocity = 0;
    break;
  case "Inversed velocity":
    newVelocity = -(velocity - d);
    break;
  default:
    break;
  }

  return new double[] {newPosition, newVelocity};
}

//callbackovi za kontrole

public void startStop()
{
  pause = !pause;
}

public void reset()
{
  pause = true;
  currentIteration = 0;

  problem = new Problem();
  particles = new Particle[particleCount];

  for (int i = 0; i < particleCount; i++)
  {
    particles[i] = new Particle();
    double particleX = randomDouble(problem.xMin, problem.xMax, true), particleY = randomDouble(problem.yMin, problem.yMax, true);
    particles[i].position[0] = particleX;
    particles[i].position[1] = particleY;
    particles[i].bestPosition[0] = particleX;
    particles[i].bestPosition[1] = particleY;
    particles[i].velocity[0] = 0.0;
    particles[i].velocity[1] = 0.0;

    double particleFunctionValue = problem.calcultateFunctionValue(particleX, particleY);
    if (particleFunctionValue < problem.minimalFunctionValue)
    {
      problem.minimalFunctionValue = particleFunctionValue;
      problem.bestPosition[0] = particleX;
      problem.bestPosition[1] = particleY;
    }
  }
}

void positionResetStrategy(int n)
{
  positionResetStrategy = (String) cf.cp5.get(ScrollableList.class, "positionResetStrategy").getItem(n).get("text");
}

void velocityResetStrategy(int n)
{
  velocityResetStrategy = (String) cf.cp5.get(ScrollableList.class, "velocityResetStrategy").getItem(n).get("text");
}

void maxIterations(int n)
{
  iterationCount = n;
}

void iterationsPerSecond(int n)
{
  iterationsPerSecond = n;
}

void particleCount(int n)
{
  particleCount = n;
  reset();
}

void omega(float n)
{
  omega = n;
  reset();
}

void c1(float n)
{
  C1 = n;
  reset();
}


void c2(float n)
{
  C2 = n;
  reset();
}

void drawCoordinateGrid() {
  stroke(50);
  textSize(12);
  fill(100);

  for (int x = (int)problem.xMin; x <= (int)problem.xMax; x++) {
    float screenX = round(map(x, (float)problem.xMin, (float)problem.xMax, 0, width));
    line(screenX, 0, screenX, height);
    text(x, screenX + 2, height - 10);
  }

  for (int y = (int)problem.yMin; y <= (int)problem.yMax; y++) {
    float screenY = round(map(y, (float)problem.yMin, (float)problem.yMax, height, 0));
    line(0, screenY, width, screenY);
    text(y, 2, screenY - 2);
  }
}

void drawParticles() {
  for (int j = 0; j < particleCount; j++) {
    float x = map((float)particles[j].position[0], (float)problem.xMin, (float)problem.xMax, 0, width);
    float y = map((float)particles[j].position[1], (float)problem.yMin, (float)problem.yMax, height, 0);
    float prevX = map((float)particles[j].previousPosition[0], (float)problem.xMin, (float)problem.xMax, 0, width);
    float prevY = map((float)particles[j].previousPosition[1], (float)problem.yMin, (float)problem.yMax, height, 0);
    color particleColor = color((j * 50) % 360, 80, 100);
    stroke(particleColor, 50);
    line(prevX, prevY, x, y);
    noStroke();
    fill(particleColor);
    ellipse(x, y, 8, 8);
  }
  float x = map((float)problem.bestPosition[0], (float)problem.xMin, (float)problem.xMax, 0, width);
  float y = map((float)problem.bestPosition[1], (float)problem.yMin, (float)problem.yMax, height, 0);
  fill(color(0, 0, 100));
  ellipse(x, y, 16, 16);
}


double randomDouble(double min, double max, boolean includeLimits)
{
  Random rand = new Random();
  double value;
  do {
    value = min + (max - min) * rand.nextDouble();
  } while (!includeLimits && (value == min || value == max));
  return value;
}

//prozor koji se otvori sa kontrolama
class ControlFrame extends PApplet {

  PApplet parent;
  public ControlP5 cp5;

  public ControlFrame(PApplet _parent) {
    super();
    parent = _parent;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public void settings() {
    size(350, 500, P2D);
  }

  public void setup() {
    surface.setLocation(1000, 10);
    cp5 = new ControlP5(this);

    cp5.setFont(font);

    //za hover prek scrollableList da se automatski otvara/zatvara
    CallbackListener toFront = new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        theEvent.getController().bringToFront();
        ((ScrollableList)theEvent.getController()).open();
      }
    };

    CallbackListener close = new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        ((ScrollableList)theEvent.getController()).close();
      }
    };

    //kontrole
    cp5.addButton("Start / Stop") //labela
      .plugTo(parent, "startStop") //uvijek ide partner i naziv callback funkcije koje su gore definirane npr. void startStop()
      .setPosition(10, 20)
      .setSize(130, 40)
      ;

    cp5.addButton("Reset")
      .plugTo(parent, "reset")
      .setPosition(170, 20)
      .setSize(100, 40)
      ;

    cp5.addScrollableList("positionResetStrategy")
      .plugTo(parent, "positionResetStrategy")
      .setPosition(10, 80)
      .setSize(100, 150)
      .setBarHeight(30)
      .setItemHeight(30)
      .addItems(new String[]{ "Border", "Random", "Reflect"})
      .setValue(0)
      .setType(ScrollableList.DROPDOWN)
      .setBackgroundColor(color(128))
      .onEnter(toFront)
      .onLeave(close)
      ;

    cp5.addScrollableList("velocityResetStrategy")
      .plugTo(parent, "velocityResetStrategy")
      .setPosition(120, 80)
      .setSize(170, 150)
      .setBarHeight(30)
      .setItemHeight(30)
      .addItems(new String[]{ "Keep current", "Set to zero", "Inversed velocity"})
      .setValue(0)
      .setType(ScrollableList.DROPDOWN)
      .setBackgroundColor(color(128))
      .onEnter(toFront)
      .onLeave(close)
      ;

    cp5.addNumberbox("Iterations per second")
      .plugTo(parent, "iterationsPerSecond")
      .setPosition(10, 120)
      .setSize(75, 20)
      .setScrollSensitivity(0.5)
      .setMin(1)
      .setMax(60)
      .setValue(1)
      ;

    cp5.addNumberbox("Max iterations")
      .plugTo(parent, "maxIterations")
      .setPosition(10, 160)
      .setSize(75, 20)
      .setScrollSensitivity(1.1)
      .setMultiplier(10)
      .setMin(1)
      .setValue(1000)
      ;

    cp5.addNumberbox("Particle count")
      .plugTo(parent, "particleCount")
      .setPosition(10, 200)
      .setSize(75, 20)
      .setScrollSensitivity(1.5)
      .setMin(1)
      .setMax(500)
      .setValue(100)
      ;

    cp5.addNumberbox("omega")
      .plugTo(parent, "omega")
      .setPosition(10, 240)
      .setSize(75, 20)
      .setScrollSensitivity(0.1)
      .setMin(0.01)
      .setMax(10.0)
      .setMultiplier(0.01)
      .setValue(0.9)
      ;

    cp5.addNumberbox("c1")
      .plugTo(parent, "c1")
      .setPosition(10, 280)
      .setSize(75, 20)
      .setScrollSensitivity(0.1)
      .setMin(0.01)
      .setMax(10.0)
      .setMultiplier(0.01)
      .setValue(0.5)
      ;

    cp5.addNumberbox("c2")
      .plugTo(parent, "c2")
      .setPosition(10, 320)
      .setSize(75, 20)
      .setScrollSensitivity(0.1)
      .setMin(0.01)
      .setMax(10.0)
      .setMultiplier(0.01)
      .setValue(0.3)
      ;
  }

  void draw() {
    background(0);
  }
}
