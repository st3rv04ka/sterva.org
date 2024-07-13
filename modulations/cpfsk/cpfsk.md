# CPFSK

CPFSK (**Continuous phase modulation**) - один из видов частотной модуляции. Отличается от FSK тем, что имеет непрерывную фазу, что помогает уменьшить размер спектра и занимаемую ширину канала. CPFSK имеет набор преимуществ перед FSK, которые будут рассмотрены после изучения внутренней работы CPFSK.

# Модуляция CPFSK

Перед переходом к CPFSK рекомендуется изучить статью про обычный FSK, которую можно найти на главной странице моего сайта. В целом, главное отличие FSK и CPFSK в том, что CPFSK не меняет фазу сиганала при переключении между частотами. То есть фаза на протяжении всего сигнала и переключений остается одна. Это позволяет передавать сигнал в ограниченной полосе пропускания, так как исключены разрывы в фазе, которые создают дополнительные частотные компоненты в спектре.

Чтобы лучше понять для чего нужна CPFSK рассмотрим следующие примеры.

![WHY CPFSK?](https://sterva.org/cpfsk/continuos-phase-frequency-shift-keying-cpfsk-3-2048.jpg)

Источник: https://www.slideshare.net/slideshow/continuos-phase-frequency-shift-keyingcpfsk/54978534

Как видно на рисунке, при переключении между генераторами в сигнале возникает разрывы фаз, при CPFSK этот разрыв убирается, это хорошо видно на следующем слайде. 

![WHY CPFSK?](https://sterva.org/cpfsk/continuos-phase-frequency-shift-keying-cpfsk-4-2048.jpg)

Источник: https://www.slideshare.net/slideshow/continuos-phase-frequency-shift-keyingcpfsk/54978534

# Модуляция CPFSK в Octave

Рассмотрим примеры и разберем математику CPFSK в Octave. Для этого используем исходные данные из статьи про FSK. Определим сигнал, который будет передаваться. У сигнала будет какая-то битовая скорость, которая будет обозначаться как **BPS**.

```
0 1 0 0 1 0 0 0 0 1 1 0 0 1
```

В FSK при модуляции мы использовали следующие параметры в Octave.

```octave
Fs = 1000;             
Tb = 1;                
t = 0:1/Fs:Tb-1/Fs;    

% Частота девиации

fsk_index = 5;
w_deviation = pi * (1/Tb) * fsk_index;
w_base = 2 * pi * 10;


w0 = w_base - w_deviation;
w1 = w_base + w_deviation;

bits = [0 1 0 0 1 0 0 0 0 1 1 0 0 1];

FSK_signal = [];
```

Частота семплирования - 1000 Герц, длительность бита - 1 секунда. Также в коде есть расчет частоты девиации, которая для CPFSK рассчитывается так же как и для FSK. Сгенерируем два сигнала, один с CPFSK, а второй с FSK, чтобы лучше понять в чем разница между двумя модуляциями. Заполним массив FSK_signal.

```octave
for i = 1:length(bits)
    if bits(i) == 0
        FSK_signal = [FSK_signal cos(w0*t)];
    else
        FSK_signal = [FSK_signal cos(w1*t)];
    end
end
```

Теперь передем непосредственно к CPFSK. Для создания непрерывного сигнала нам нужно контролировать фазу, самый простой способ - пересчитывать фазу при добавлении бита. Разберем формулы для реализации. В непрерывном времени изменение фазы в течении маленького интеравала времени dt определяется следующим образом.
$$
dϕ = w * dt
$$
Теперь при дискретизации с частотой дискретизации Fs (задана в начале статьи и равна 1000 отсчетов в секунду) формула превращается в следующий вариант.
$$
Δϕ = w * (1 / Fs)
$$
Следовательно обновление фазы будет выглядить так.
$$
ϕ_{n+1} = ϕ_n + Δϕ  
$$
Следовательно конечная формула.
$$
phase = phase + freq * 1/Fs \\
phase = phase + freq / Fs
$$
Теперь попробуем применить ее на практике и посмотреть моменты переключения на графиках, которые сгенерирует Octave.

```octave
phase = 0;
CPFSK_signal = [];
for i = 1:length(bits)
    if bits(i) == 0
        freq = w0;
    else
        freq = w1;
    end
    for j = 1:length(t)
        phase = phase + freq / Fs;
        CPFSK_signal = [CPFSK_signal cos(phase)];
    end
end
```

Суть остается прежней, просто меняем фазу. Теперь можно сравнить что у нас получилось. Для этого отрисуем графики сигналов и изучим переходы между частотами.

```octave
figure;

subplot(4,1,1);
plot(t, cos(w0*t));
title('FSK Frequency for bit 0');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,2);
plot(t, cos(w1*t));
title('FSK Frequency for bit 1');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(4,1,3);
plot(0:1/Fs:(length(FSK_signal)-1)/Fs, FSK_signal);
title('FSK Modulated Signal');
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 2]);

subplot(4,1,4);
plot(0:1/Fs:(length(CPFSK_signal)-1)/Fs, CPFSK_signal);
title('CPFSK Modulated Signal');
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 2]);
```

Время в графиках ограничено до 2 секунд, чтобы можно было четко найти переход от 0 на 1. 

![Signal FSK and CPFSK](https://sterva.org/cpfsk/signal.jpeg)

Также изучим спектральные различия между двумя модуляциями. 

```octave
N = length(CPFSK_signal);
f = (-N/2:N/2-1)*(Fs/N);

Y_FSK = fftshift(fft(FSK_signal, N));
Y_CPFSK = fftshift(fft(CPFSK_signal, N));

P_FSK = abs(Y_FSK/N);
P_CPFSK = abs(Y_CPFSK/N);

figure;

subplot(2,1,1);
plot(f, P_FSK);
title('Spectrum of FSK Modulated Signal');
xlabel('Frequency (Hz)');
ylabel('|P(f)|');
xlim([-100 100]); 

subplot(2,1,2);
plot(f, P_CPFSK);
title('Spectrum of CPFSK Modulated Signal');
xlabel('Frequency (Hz)');
ylabel('|P(f)|');
xlim([-100 100]);
```

Получаем следующие графики.

![Spectr FSK and CPFSK](https://sterva.org/cpfsk/spectr.jpeg)

Как видно на графиках, различия значительны. CPFSK не создает боковых частотных компонентов в спектре из-за плавного перехода, за счет этого его спектр получается намного уже, что позволяет экономить место в пропускной полосе, при этом сохраняя скорость передачи данных.

# Ресурсы

https://astro.tsu.ru/TGP/text/6_1_2.htm
https://en.wikipedia.org/wiki/Phase_(waves)
https://en.wikipedia.org/wiki/Continuous_phase_modulation
https://signals.radioscanner.ru/info/item68/
http://www.radioscanner.ru/info/article345/
