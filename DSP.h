#include <SFML/Audio.hpp>
#include <iostream>
#include <complex>
#include <valarray>
#include <math.h>

const double PI = 3.141592653589793238460;

typedef std::complex<double> Complex;
typedef std::valarray<Complex> CArray;

class FFT {
  public:
    FFT(std::string const& _path, int const& _bufferSize);

    void hammingWindow();
    void fft(CArray &x);
    bool detectBeat();
    int sensitivity;

  private:
    std::string path;
    sf::SoundBuffer buffer;
    sf::Sound sound;

    std::vector<Complex> sample;
    std::vector<float> window;
    CArray bin;

    int sampleRate;
    int sampleCount;
    int bufferSize;
    int mark;
};