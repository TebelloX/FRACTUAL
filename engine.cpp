#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>
#include <SFML/OpenGL.hpp>
#include <INI/SimpleIni.h>
#include <iostream>
#include <complex>
#include <cmath>
#include <iterator>
#include <fstream>
#include <valarray>
#include "DSP.h"

/**
 * INIT SETTINGS VARIABLES
 */
int   WIDTH;
int   HEIGHT;
float POWER;
float DARKNESS;
float BLACKANDWHITE;
float COLORAMIX;
float COLORBMIX;

std::string SONG;
std::string FRACTAL;

/* ----------[HELPER FUNCTIONS]---------- */

// rounds float to 2 decimal places
float truncf2d(float var) {
  float value = (int)(var * 100000 + 0.5);
  return (float)value / 100000;
}

void InitSettings() {
  CSimpleIniA ini;
  
  SI_Error rc = ini.LoadFile("config.ini");
  if (rc < 0) {
    std::cout << "[!] Error loading config file" << std::endl;
  } else {
    std::cout << "[!] Loaded config file" << std::endl;

    // Integer
    HEIGHT = atoi(ini.GetValue("APPLICATION", "height", "default"));
    WIDTH = atoi(ini.GetValue("APPLICATION", "width", "default"));

    // Float
    POWER = atof(ini.GetValue("MANDLEBULB", "power", "default"));
    DARKNESS = atof(ini.GetValue("MANDLEBULB", "darkness", "default"));
    BLACKANDWHITE = atof(ini.GetValue("MANDLEBULB", "blackAndWhite", "default"));
    COLORAMIX = atof(ini.GetValue("MANDLEBULB", "colorAMix", "default"));
    COLORBMIX = atof(ini.GetValue("MANDLEBULB", "colorBMix", "default"));

    // std:string
    const char* songChar = ini.GetValue("MUSIC", "song", "default");
    SONG = songChar;

    const char* fractalChar = ini.GetValue("VISUALIZER", "fractal", "default");
    FRACTAL = fractalChar;
  }
}
/* -------------------------------------- */

int main() {
  InitSettings();

  sf::ContextSettings settings;
  settings.depthBits = 24;
  settings.stencilBits = 8;
  settings.antialiasingLevel = 4;
  settings.majorVersion = 3;
  settings.minorVersion = 0;

  sf::RenderWindow window(sf::VideoMode(WIDTH, HEIGHT), "FRACTUAL v0.1", sf::Style::Default, settings);
  window.setFramerateLimit(60);
  window.setActive(true);
  
  sf::Image icon;
  icon.loadFromFile("resources/icon.png");

  window.setIcon(icon.getSize().x, icon.getSize().y, icon.getPixelsPtr());

  std::cout << "[!] Playing song & starting visualizer" << std::endl;

  // DSP stuff
  std::string songPath = "songs/" + SONG;
  const int bufferSize = 16384;
  FFT _fft(songPath, bufferSize);
  _fft.sensitivity = 8; // [higher => higher minimum amplitude]

  sf::Font font;
  if (!font.loadFromFile("fonts/FiraCode-Regular.ttf")) {
    return 1;
  }

  sf::Text MENU_TEXT;
  MENU_TEXT.setFont(font);
  MENU_TEXT.setString("DEBUG OUTPUT");
  MENU_TEXT.setCharacterSize(12);
  MENU_TEXT.setFillColor(sf::Color::Cyan);

  sf::Text DIVIDER_TEXT;
  DIVIDER_TEXT.setPosition(0.f, 14.f);
  DIVIDER_TEXT.setFont(font);
  DIVIDER_TEXT.setString("------------");
  DIVIDER_TEXT.setCharacterSize(12);
  DIVIDER_TEXT.setFillColor(sf::Color::Cyan);

  sf::Text FPS_TEXT;
  FPS_TEXT.setPosition(0.f, 28.f);
  FPS_TEXT.setFont(font);
  FPS_TEXT.setString("FPS: 0");
  FPS_TEXT.setCharacterSize(12);
  FPS_TEXT.setFillColor(sf::Color::Cyan);

  sf::Text POWER_TEXT;
  POWER_TEXT.setPosition(0.f, 42.f);
  POWER_TEXT.setFont(font);
  POWER_TEXT.setString("POWER: 0");
  POWER_TEXT.setCharacterSize(12);
  POWER_TEXT.setFillColor(sf::Color::Red);

  sf::RectangleShape rect;
  rect.setSize(sf::Vector2f((float)WIDTH, (float)HEIGHT));

  if (!sf::Shader::isAvailable()) {
    // shaders not available
    return 1;
  }

  sf::Shader shader;
  if (!shader.loadFromFile("shaders/vert.glsl", sf::Shader::Vertex)) {
    std::cout << "[!] Could not load vertex shader" << std::endl;
    return 1;
  }

  std::string fractalShader = "shaders/" + FRACTAL + ".glsl";

  if (!shader.loadFromFile(fractalShader, sf::Shader::Fragment)) {
    std::cout << "[!] Could not load fragment shader" << std::endl;
    return 1;
  }

  std::cout << "[!] Loaded shaders successfully" << std::endl;

  shader.setUniform("iResolution", sf::Glsl::Vec2(WIDTH, HEIGHT));

  sf::Clock clock;
  float prevTime = 0.f;

  // Main render loop
  bool running = true;

  while (running) {
    // handle events
    sf::Event event;
    while (window.pollEvent(event)) {
      if (event.type == sf::Event::Closed) {
        // end the program
        running = false;
      } else if (event.type == sf::Event::Resized) {
        // adjust the viewport when the window is resized
        shader.setUniform("iResolution", sf::Glsl::Vec2(WIDTH, HEIGHT));
      } else if (event.type == sf::Event::KeyPressed) {
        if (event.key.code == sf::Keyboard::Space) {
          POWER = 1.0;
        }
      }
    } 

    bool didDetectBeat;
    didDetectBeat = _fft.detectBeat();
    if (didDetectBeat) {
      // std::cout << "Beat" << std::endl;
      POWER_TEXT.setString("BEAT DETECTION: [<");
    } else {
      POWER_TEXT.setString("BEAT DETECTION: [   <");
    }

    sf::Time elapsed = clock.getElapsedTime();
    shader.setUniform("iTime", (float)elapsed.asSeconds());

    float currTime = (float)elapsed.asSeconds();
    shader.setUniform("power", POWER * (currTime / 4));
    shader.setUniform("darkness", DARKNESS);
    shader.setUniform("blackAndWhite", BLACKANDWHITE);
    shader.setUniform("colorAMix", sf::Glsl::Vec3(COLORAMIX,COLORAMIX,COLORAMIX));
    shader.setUniform("colorBMix", sf::Glsl::Vec3(COLORBMIX,COLORBMIX,COLORBMIX));

    // clear the buffers
    sf::Color clearColor(0, 0, 0, 255);
    window.clear(clearColor);

    // draw fractal
    window.draw(rect, &shader);

    //draw text
    float fps = 1.f / (currTime - prevTime);
    prevTime = currTime;
    float roundedFps = truncf2d(fps);
    FPS_TEXT.setString("FPS: " + std::to_string(roundedFps));
    window.draw(FPS_TEXT);

    window.draw(POWER_TEXT);
    window.draw(MENU_TEXT);
    window.draw(DIVIDER_TEXT);

    // float roundedPower = truncf2d(POWER * (currTime / 4));
    // POWER_TEXT.setString("POWER: " + std::to_string(roundedPower));
    // window.draw(POWER_TEXT);

    // end the current frame (internally swaps the front and back buffers)
    window.display();
  }

  return 0;
}