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
