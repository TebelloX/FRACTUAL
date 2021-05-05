#include <SFML/Graphics.hpp>
#include <SFML/OpenGL.hpp>
#include <iostream>
#include <complex>
#include <math.h>
#include <fstream>

int main() {
  sf::ContextSettings settings;
  settings.depthBits = 24;
  settings.stencilBits = 8;
  settings.antialiasingLevel = 4;
  settings.majorVersion = 3;
  settings.minorVersion = 0;

  const int window_w = 800;
  const int window_h = 600;

  sf::RenderWindow window(sf::VideoMode(window_w, window_h), "My window", sf::Style::Default, settings);
  window.setFramerateLimit(60);
  window.setActive(true);

  sf::Texture tex;
  tex.create(window_w, window_h);
  sf::RectangleShape rect;
  rect.setSize(sf::Vector2f((float)window_w, (float)window_h));
  

  // sf::Texture tex;
  // tex.create(window_w, window_h);
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

  shader.setUniform("iResolution", sf::Glsl::Vec2(window_w, window_h));

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
    shader.setUniform("iTime", (float)elapsed.asSeconds());

    // clear the buffers
    // glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // draw...
    window.draw(rect, &shader);


    // end the current frame (internally swaps the front and back buffers)
    window.display();
  }

  return 0;
}