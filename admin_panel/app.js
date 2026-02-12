document.addEventListener('DOMContentLoaded', () => {
    initCharts();
    setupSidebar();
    setupThemeToggle();
});

function setupSidebar() {
    const sidebar = document.querySelector('aside');
    const menuBtn = document.getElementById('menu-toggle');
    const closeBtn = document.getElementById('sidebar-close'); // Optional if we add one

    if (menuBtn) {
        menuBtn.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });
    }

    // Close sidebar when clicking outside on mobile
    document.addEventListener('click', (e) => {
        if (window.innerWidth <= 1024) {
            if (!sidebar.contains(e.target) && !menuBtn.contains(e.target) && sidebar.classList.contains('open')) {
                sidebar.classList.remove('open');
            }
        }
    });
}

function setupThemeToggle() {
    const themeBtn = document.getElementById('theme-toggle');
    const html = document.documentElement;
    const icon = themeBtn ? themeBtn.querySelector('.material-icons') : null;

    // Check saved preference
    if (localStorage.getItem('theme') === 'dark' || 
        (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        html.classList.add('dark');
        if (icon) icon.textContent = 'light_mode';
    } else {
        html.classList.remove('dark');
        if (icon) icon.textContent = 'dark_mode';
    }

    if (themeBtn) {
        themeBtn.addEventListener('click', () => {
            html.classList.toggle('dark');
            const isDark = html.classList.contains('dark');
            localStorage.setItem('theme', isDark ? 'dark' : 'light');
            if (icon) icon.textContent = isDark ? 'light_mode' : 'dark_mode';
            
            // Re-render charts to update colors if necessary
            updateChartsTheme(isDark);
        });
    }
}

let streamingChart = null;
let genreChart = null;

function initCharts() {
    const ctxStreaming = document.getElementById('streamingChart');
    const ctxGenre = document.getElementById('genreChart');

    if (!ctxStreaming || !ctxGenre) return;

    // Remove placeholder divs if they exist inside the chart containers
    // (We will replace the HTML structure to use <canvas> instead of divs)

    const primaryColor = '#e48744';
    const isDark = document.documentElement.classList.contains('dark');
    const gridColor = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)';
    const textColor = isDark ? '#94a3b8' : '#64748b';

    // Streaming Trends Chart (Line)
    streamingChart = new Chart(ctxStreaming, {
        type: 'line',
        data: {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            datasets: [{
                label: 'Streams',
                data: [3200, 4100, 3800, 5200, 4800, 6100, 5900],
                borderColor: primaryColor,
                backgroundColor: (context) => {
                    const ctx = context.chart.ctx;
                    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
                    gradient.addColorStop(0, 'rgba(228, 135, 68, 0.5)');
                    gradient.addColorStop(1, 'rgba(228, 135, 68, 0.0)');
                    return gradient;
                },
                borderWidth: 3,
                tension: 0.4,
                fill: true,
                pointBackgroundColor: '#fff',
                pointBorderColor: primaryColor,
                pointBorderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    backgroundColor: isDark ? '#1e293b' : '#fff',
                    titleColor: isDark ? '#fff' : '#1e293b',
                    bodyColor: isDark ? '#cbd5e1' : '#475569',
                    borderColor: isDark ? '#334155' : '#e2e8f0',
                    borderWidth: 1,
                    padding: 10,
                    displayColors: false,
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: gridColor,
                        borderDash: [5, 5]
                    },
                    ticks: {
                        color: textColor
                    }
                },
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        color: textColor
                    }
                }
            }
        }
    });

    // Genre Chart (Doughnut)
    genreChart = new Chart(ctxGenre, {
        type: 'doughnut',
        data: {
            labels: ['Lofi Focus', 'Acoustic', 'Ambient', 'Cinematic'],
            datasets: [{
                data: [42, 28, 18, 12],
                backgroundColor: [
                    '#e48744', 
                    'rgba(228, 135, 68, 0.7)', 
                    'rgba(228, 135, 68, 0.4)', 
                    'rgba(228, 135, 68, 0.2)'
                ],
                borderWidth: 0,
                hoverOffset: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '75%',
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    backgroundColor: isDark ? '#1e293b' : '#fff',
                    titleColor: isDark ? '#fff' : '#1e293b',
                    bodyColor: isDark ? '#cbd5e1' : '#475569',
                    borderColor: isDark ? '#334155' : '#e2e8f0',
                    borderWidth: 1
                }
            }
        }
    });
}

function updateChartsTheme(isDark) {
    if (!streamingChart || !genreChart) return;

    const gridColor = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)';
    const textColor = isDark ? '#94a3b8' : '#64748b';

    streamingChart.options.scales.y.grid.color = gridColor;
    streamingChart.options.scales.y.ticks.color = textColor;
    streamingChart.options.scales.x.ticks.color = textColor;
    streamingChart.options.plugins.tooltip.backgroundColor = isDark ? '#1e293b' : '#fff';
    streamingChart.options.plugins.tooltip.titleColor = isDark ? '#fff' : '#1e293b';
    streamingChart.options.plugins.tooltip.bodyColor = isDark ? '#cbd5e1' : '#475569';
    streamingChart.options.plugins.tooltip.borderColor = isDark ? '#334155' : '#e2e8f0';
    streamingChart.update();

    genreChart.options.plugins.tooltip.backgroundColor = isDark ? '#1e293b' : '#fff';
    genreChart.options.plugins.tooltip.titleColor = isDark ? '#fff' : '#1e293b';
    genreChart.options.plugins.tooltip.bodyColor = isDark ? '#cbd5e1' : '#475569';
    genreChart.options.plugins.tooltip.borderColor = isDark ? '#334155' : '#e2e8f0';
    genreChart.update();
}


// --- Add Track Wizard Logic ---

let currentStep = 1;

function showStep(step) {
    // Hide all steps
    document.querySelectorAll('.step-content').forEach(el => {
        el.classList.add('hidden');
        el.classList.remove('block');
    });

    // Show current step
    const currentStepEl = document.getElementById(`step-${step}`);
    if (currentStepEl) {
        currentStepEl.classList.remove('hidden');
        currentStepEl.classList.add('block');
    }

    // Update Stepper UI
    document.querySelectorAll('.step-indicator').forEach(el => {
        const stepNum = parseInt(el.dataset.step);
        const circle = el.querySelector('div');
        const label = el.querySelector('span');

        if (stepNum < step) {
            // Completed
            circle.classList.remove('bg-card-light', 'dark:bg-[#2d241d]', 'border-2', 'text-neutral-warm', 'ring-4');
            circle.classList.add('bg-primary', 'text-white', 'ring-0');
            circle.innerHTML = '<span class="material-icons text-lg">check</span>';
            label.classList.add('text-primary');
            label.classList.remove('text-neutral-warm');
        } else if (stepNum === step) {
            // Active
            circle.classList.remove('bg-card-light', 'dark:bg-[#2d241d]', 'border-2', 'text-neutral-warm');
            circle.classList.add('bg-primary', 'text-white');
            circle.innerHTML = stepNum;
            label.classList.add('text-primary');
            label.classList.remove('text-neutral-warm');
        } else {
            // Inactive
            circle.classList.remove('bg-primary', 'text-white', 'ring-0');
            circle.classList.add('bg-card-light', 'dark:bg-[#2d241d]', 'border-2', 'border-primary/20', 'text-neutral-warm');
            circle.innerHTML = stepNum;
            label.classList.remove('text-primary');
            label.classList.add('text-neutral-warm');
        }
    });

    // Update Footer Visibility
    const footer = document.getElementById('wizard-footer');
    if (footer) {
        if (step === 4) {
             footer.classList.add('hidden');
        } else {
             footer.classList.remove('hidden');
        }

        // Hide Previous button on Step 1
        const prevBtn = document.getElementById('prevBtn');
        if (prevBtn) prevBtn.style.visibility = step === 1 ? 'hidden' : 'visible';
    }
    
    currentStep = step;
}

function nextStep() {
    if (currentStep < 4) {
        showStep(currentStep + 1);
        window.scrollTo(0, 0);
    }
}

function prevStep() {
    if (currentStep > 1) {
        showStep(currentStep - 1);
        window.scrollTo(0, 0);
    }
}

function toggleStep(step) {
    showStep(step);
    window.scrollTo(0, 0);
}

// Initialize wizard if on the page
if (document.getElementById('wizard-form')) {
    // Add click event listeners to stepper
    document.querySelectorAll('.step-indicator').forEach(el => {
        el.addEventListener('click', () => {
            const step = parseInt(el.dataset.step);
            // Only allow clicking previous steps or current step (optional restriction)
            // For now allowing all for functionality demo
            showStep(step);
        });
    });

    showStep(1);
}
