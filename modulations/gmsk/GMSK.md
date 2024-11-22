# GMSK

GMSK - вид частотной модуляции с минимальным разносом частот (как у MSK) при которой последовательность последовательных прямоугольных импульсов дополнительно проходит через гауссовский фильтр нижних частот.

# Модуляция GMSK

Перед чтением рекомендую ознакомиться с MSK, так как GMSK и MSK непосредственно связаны. Ссылки на все модуляции можно найти на главной странице моего сайта. Главным отличием GMSK является гауссовский фильтр нижний частот, который позволяет максимально снизить уровень внеполосных излучений и тем самым уменьшить ширину спектра.



Модулирующий сигнал, то есть поток из 0 и 1 приводится к виду -1 и +1, которые потом фильтруется таким образом, что импульсы преобразуются в импульсы гауссовского вида. Что это значит? Под гауссовским видом импульса понимают колоколообразный импульс, который имеет форму колокола. Разберем пример на битовой последовательности из MSK.

```octave
Fs = 1000;
Tb = 1;
t = 0:1/Fs:Tb-1/Fs;

bits = [0 1 0 0 1 1 0 1 0 1];
N_bits = length(bits);

nrz_signal = 2 * bits - 1;

nrz_signal_upsampled = repelem(nrz_signal, length(t));

BT = 0.3;
alpha = sqrt(log(2) / 2) / (BT);
time_gaussian_filter = linspace(-4, 4, 8 * Fs);
gaussian_filter = exp(-2 * (pi * alpha * time_gaussian_filter).^2);

nrz_filtered = conv(nrz_signal_upsampled, gaussian_filter, 'same');

figure;

subplot(2, 1, 1);
plot(linspace(0, N_bits, length(nrz_signal_upsampled)), nrz_signal_upsampled, 'LineWidth', 2);
title('NRZ Signal (from -1 to +1)');
xlabel('Time');
ylabel('Amp');
grid on;

subplot(2, 1, 2);
plot(linspace(0, N_bits, length(nrz_filtered)), nrz_filtered, 'LineWidth', 2);
title('NRZ with Gaussian filter');
xlabel('Time');
ylabel('Amp');
grid on;

```

Разницу при обработке фильтром гаусса хорошо видно на графиках.

![nrz_g](/home/bbb/Projects/streva.org/modulations/gmsk/nrz_g.jpeg)

# Гауссовский фильтр

Гауссовский фильтр - это особый вид фильтра, который имеет гауссовую форму как во временной, так и в частотной области. В частотной области его формат также описывается гауссовской функцией, что делает его эффективным для сглаживания сигналов. Этот тип фильтров делает края "мягкими", то есть они переходят плавно.



Во временной области гауссовский фильтр выглядит следующим образом:
$$
h(t) = exp(-\frac{t^2}{2\sigma^2})
$$
Где:

- h(t) - импульсная характеристика фильтра во временной области,
- t - временная ось,
- sigma - стандартное отклонение, которое контролирует ширину фильтра (чем меньше, тем более узкий фильтр и сильнее воздействие не высокие частоты).

Проследить влияние sigma на исходный сигнал можно использовав следующий код для Octave.

```octave
Fs = 1000;
Tb = 1;
t = 0:1/Fs:Tb-1/Fs;

bits = [0 1 0 0 1 1 0 1 0 1];
N_bits = length(bits);

nrz_signal = 2 * bits - 1;

nrz_signal_upsampled = repelem(nrz_signal, length(t));

time_gaussian_filter = linspace(-4, 4, 8 * Fs);

sigma_values = [0.1, 0.5, 1, 2];

figure;

for i = 1:length(sigma_values)
    sigma = sigma_values(i);
    gaussian_filter = exp(-time_gaussian_filter.^2 / (2 * sigma^2));
    gaussian_filter = gaussian_filter / sum(gaussian_filter);

    nrz_filtered = conv(nrz_signal_upsampled, gaussian_filter, 'same');

    subplot(length(sigma_values), 1, i);
    plot(linspace(0, N_bits, length(nrz_filtered)), nrz_filtered, 'LineWidth', 2);
    title(['NRZ with Gaussian filter, \sigma = ', num2str(sigma)]);
    xlabel('Time');
    ylabel('Amplitude');
    grid on;
end
```

При запуске получаем следующий график для sigma 0.1, 0.5, 1 и 2.

![sigma](/home/bbb/Projects/streva.org/modulations/gmsk/sigma.jpg)

На графике прекрасно видно, что при увеличении сигма края исходного сигнала становятся более размытыми, а при большом значении их становится невозможно различить. Для более наглядной демонстрации GMSK изучим спектр сигнала после прохождения исходного сигнала через фильтр Гаусса.



## Спектр GMSK

Для изучения спектра GMSK используем следующий код для Octave. При этом слудует обратить внимания на разные значения sigma, в некоторых источниках этот параметр называется BT, но он напрямую связан с sigma.
$$
\sigma = \frac{1}{2\pi*BT}
$$
Формула показывает связь между сигма и BT. Контролируя BT при модуляции можно выбирать оптимальную ширину спектра и ISI (intersymbol interference), который мы рассмотрим ниже, так как это очень важное определения для GMSK. Теперь изучим код для анализа спектра.

```octave
Fs = 1000;
Tb = 1;
t = 0:1/Fs:Tb-1/Fs;

bits = [0 1 0 0 1 1 0 1 0 1];
N_bits = length(bits);

nrz_signal = 2 * bits - 1;
nrz_signal_upsampled = repelem(nrz_signal, length(t));

sigma_values = [0.1, 0.5, 1, 2];
time_gaussian_filter = linspace(-4, 4, 8 * Fs);

figure;

for i = 1:length(sigma_values)
    sigma = sigma_values(i);
    h = exp(-time_gaussian_filter.^2 / (2 * sigma^2));
    h = h / sum(h);

    nrz_filtered = conv(nrz_signal_upsampled, h, 'same');

    subplot(length(sigma_values) + 1, 2, 2 * i - 1);
    plot(linspace(0, N_bits, length(nrz_filtered)), nrz_filtered, 'LineWidth', 2);
    title(['Filtered Signal, \sigma = ', num2str(sigma)]);
    xlabel('Time');
    ylabel('Amplitude');
    grid on;

    subplot(length(sigma_values) + 1, 2, 2 * i);
    fft_spectrum = abs(fftshift(fft(nrz_filtered)));
    freq_axis = linspace(-Fs/2, Fs/2, length(fft_spectrum));
    plot(freq_axis, fft_spectrum, 'LineWidth', 2);
    xlim([-15 15]);
    title(['Spectrum, \sigma = ', num2str(sigma)]);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    grid on;
end

subplot(length(sigma_values) + 1, 2, 2 * length(sigma_values) + 1);
plot(linspace(0, N_bits, length(nrz_signal_upsampled)), nrz_signal_upsampled, 'LineWidth', 2);
title('Unfiltered Signal');
xlabel('Time');
ylabel('Amplitude');
grid on;

subplot(length(sigma_values) + 1, 2, 2 * length(sigma_values) + 2);
fft_spectrum_unfiltered = abs(fftshift(fft(nrz_signal_upsampled)));
freq_axis_unfiltered = linspace(-Fs/2, Fs/2, length(fft_spectrum_unfiltered));
plot(freq_axis_unfiltered, fft_spectrum_unfiltered, 'LineWidth', 2);
xlim([-15 15]);
title('Unfiltered Spectrum');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;
```

При запуска получаем следующий график.

![spect](/home/bbb/Projects/streva.org/modulations/gmsk/spect.jpg)

На графике четко видно, что обычный сигнал без фильтра Гаусса занимает довольно широкий спектр, так как имеет множество внеполосных излучений, который появляются из-за резких изменений сигнала. В других случаях используется фильтр Гаусса с определенной sigma. Чем больше sigma, тем меньше занимаемый спектр. При использовании слишком большого сигма можно сигнал становится невозможно распознать. Это главный минус GMSK, для его приема нужен довольно хороший сигнал, так как на больших сигма сложно различить исходные данные.



## Intersymbol Interference (ISI)

Интерсимвольная интерференция - это явление, при котором сигналы или символы накладываются друг на друга, это было хорошо видно при сигма 2, на верхнем графике, где сигнал стал похож на что-то однородное. Это сильно усложняет прием и требует более сложных конструкций приемников. Про GMSK необходимо точно выбрать значение BT, чтобы получить нужную ширину спектра и не получит слишком сложный сигнал. Проследить влияние ISI на сигнал при большом BT можно на eye-диаграмме, которая позволяет наглядно оценить интерференцию между символами.

```octave
Fs = 1000;
Tb = 1;
t = 0:1/Fs:Tb-1/Fs;

bits = randi([0 1], 1, 1000);
N_bits = length(bits);

nrz_signal = 2 * bits - 1;
nrz_signal_upsampled = repelem(nrz_signal, length(t));

sigma_values = [0.1, 0.5, 1, 2];
time_gaussian_filter = linspace(-4, 4, 8 * Fs);

figure;

for i = 1:length(sigma_values)
    sigma = sigma_values(i);
    gaussian_filter = exp(-time_gaussian_filter.^2 / (2 * sigma^2));
    gaussian_filter = gaussian_filter / sum(gaussian_filter);

    nrz_filtered = conv(nrz_signal_upsampled, gaussian_filter, 'same');

    samples_per_bit = length(t);
    eye_period = 2 * samples_per_bit;
    num_segments = floor(length(nrz_filtered) / eye_period);

    eye_data = reshape(nrz_filtered(1:num_segments*eye_period), eye_period, num_segments);

    subplot(length(sigma_values), 1, i);
    plot(linspace(0, 2*Tb, eye_period), eye_data, 'b');
    title(['Eye Diagram for \sigma = ', num2str(sigma)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
end

sgtitle('Effect of \sigma on ISI Demonstrated by Eye Diagrams');

```

При запуске получаем следующие графики. 

![isi](/home/bbb/Projects/streva.org/modulations/gmsk/isi.jpg)

Как видно при меньших BT (sigma) глаза "открыты", что означает малую интерференцию, однако при больших значениях можно наблюдать большую интерференцию, глаза "закрыты".
