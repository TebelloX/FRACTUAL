#include "DSP.h"

FFT::FFT(std::string const& _path, int const& _bufferSize) {
	path = _path;

	if (!buffer.loadFromFile(path))
    std::cout << "[!] Unable to load buffer" << std::endl;

	sound.setBuffer(buffer);
	sound.setLoop(true);
	sound.play();

	sampleRate = buffer.getSampleRate() * buffer.getChannelCount();
	sampleCount = buffer.getSampleCount();

	if(_bufferSize < sampleCount)
    bufferSize = _bufferSize;
	else
    bufferSize = sampleCount;

	mark = 0;

	for(int i(0); i < bufferSize; i++) 
    window.push_back(0.54-0.46*cos(2*PI*i/(float)bufferSize));

	sample.resize(bufferSize);
}

void FFT::hammingWindow() {
  mark = sound.getPlayingOffset().asSeconds() * sampleRate;

  if (mark + bufferSize < sampleCount) {
    for (int i(mark); i < bufferSize + mark; i++) {
      sample[i-mark] = Complex(buffer.getSamples()[i] * window[i-mark], 0);
    }
  }
}

void FFT::fft(CArray &x) {
  const int N = x.size();
  if (N <= 1) return;

  CArray even = x[std::slice(0, N/2, 2)];
  CArray odd = x[std::slice(1, N/2, 2)];

  fft(even);
  fft(odd);

  for (int k = 0; k < N/2; k++) {
    Complex t = std::polar(1.0, -2 * PI * k / N) * odd[k];
    x[k] = even[k] + t;
    x[k+N/2] = even[k] - t;
  }
}

bool FFT::detectBeat() {
  hammingWindow();
  bin = CArray(sample.data(), bufferSize);
  fft(bin);
  float max = 100000000;
  for (int i = 0; i < sizeof(bin); i++) {
    // calculate amplitude and freq
    Complex freqVals = bin[i];
    double a = freqVals.real();
    double b = freqVals.imag();
    double ampRaw = sqrt(a * a + b * b);
    double amp = ampRaw / sampleCount;
    double freq = (2 * PI * ampRaw) / sampleCount;

    // beat detection
    if (amp >= sensitivity) {
      std::cout << "AMP: " << amp << std::endl;
      std::cout << "FRQ: " << freq << " Hz" << std::endl;
      return true;
    }
  }
  return false;
}