#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>
#include <SFML/OpenGL.hpp>
#include <INI/SimpleIni.h>
#include <iostream>
#include <complex>
#include <math.h>
#include <fstream>

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
    POWER = atof(ini.GetValue("MANDELBULB", "power", "default"));
    DARKNESS = atof(ini.GetValue("MANDELBULB", "darkness", "default"));
    BLACKANDWHITE = atof(ini.GetValue("MANDELBULB", "blackAndWhite", "default"));
    COLORAMIX = atof(ini.GetValue("MANDELBULB", "colorAMix", "default"));
    COLORBMIX = atof(ini.GetValue("MANDELBULB", "colorBMix", "default"));

    // std:string
    const char* songChar = ini.GetValue("MUSIC", "song", "default");
    SONG = songChar;
  }
}

int main() {
  InitSettings();

  sf::ContextSettings settings;
  settings.depthBits = 24;
  settings.stencilBits = 8;
  settings.antialiasingLevel = 4;
  settings.majorVersion = 3;
  settings.minorVersion = 0;

  sf::RenderWindow window(sf::VideoMode(WIDTH, HEIGHT), "Fractual Visualizer", sf::Style::Default, settings);
  window.setFramerateLimit(60);
  window.setActive(true);

  sf::SoundBuffer buffer;
  if (!buffer.loadFromFile("songs/" + SONG)) {
    std::cout << "[!] Could not load song" << std::endl;
    return 1;
  } else {
    std::cout << "[!] Loaded song: " << SONG << std::endl;
  }

  sf::Sound song;
  song.setBuffer(buffer);
  song.play();
  std::cout << "[!] Playing song & starting visualizer" << std::endl;

  sf::RectangleShape rect;
  rect.setSize(sf::Vector2f((float)WIDTH, (float)HEIGHT));

  // sf::Texture tex;
  // tex.create(WIDTH, HEIGHT);
  // sf::Sprite spr(tex);

  if (!sf::Shader::isAvailable()) {
  // shaders no available
  return 1;
  }

  sf::Shader shader;
  if (!shader.loadFromFile("shaders/vert.glsl", sf::Shader::Vertex)) {
    std::cout << "[!] Could not load vertex shader" << std::endl;
    return 1;
  }

  if (!shader.loadFromFile("shaders/frag.glsl", sf::Shader::Fragment)) {
    std::cout << "[!] Could not load fragment shader" << std::endl;
    return 1;
  }

  std::cout << "[!] Loaded shaders successfully" << std::endl;

  shader.setUniform("iResolution", sf::Glsl::Vec2(WIDTH, HEIGHT));

  sf::Clock clock;

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

      }
    }

    sf::Time elapsed = clock.getElapsedTime();
    // shader.setUniform("iTime", (float)elapsed.asSeconds());

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


    // end the current frame (internally swaps the front and back buffers)
    window.display();
  }

  return 0;
}