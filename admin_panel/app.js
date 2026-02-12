import { db, storage } from './firebase-config.js';
import { collection, onSnapshot, doc, updateDoc, deleteDoc, getDocs, query, where, orderBy, limit, startAfter, getCountFromServer, addDoc, Timestamp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js';

document.addEventListener('DOMContentLoaded', () => {
    initCharts();
    setupSidebar();
    setupThemeToggle();
    
    if (document.getElementById('users-table-body')) {
        initUserManagement();
    }
    
    if (document.getElementById('tracks-table-body')) {
        initMusicManagement();
    }
    
    if (document.getElementById('wizard-form')) {
        initTrackWizard();
    }
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
                data: [0, 0, 0, 0, 0, 0, 0],
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
                data: [0.1, 0, 0, 0],
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

// ===== USER MANAGEMENT FUNCTIONS =====

let usersUnsubscribe = null;
let currentPage = 1;
let usersPerPage = 10;
let totalUsers = 0;
let lastVisibleDoc = null;
let firstVisibleDoc = null;
let pageCache = new Map();

function initUserManagement() {
    fetchUserStats();
    loadUsers(1);
    setupPaginationControls();
}

async function fetchUserStats() {
    try {
        const usersCollection = collection(db, 'users');
        
        const totalSnapshot = await getCountFromServer(usersCollection);
        totalUsers = totalSnapshot.data().count;
        
        const now = new Date();
        const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        
        const activeQuery = query(
            usersCollection,
            where('lastActive', '>=', twentyFourHoursAgo.toISOString())
        );
        const activeSnapshot = await getDocs(activeQuery);
        const activeCount = activeSnapshot.size;
        
        const pendingQuery1 = query(
            usersCollection,
            where('verificationStatus', '==', 'pending')
        );
        const pendingSnapshot1 = await getDocs(pendingQuery1);
        
        const pendingQuery2 = query(
            usersCollection,
            where('isVerified', '==', false)
        );
        const pendingSnapshot2 = await getDocs(pendingQuery2);
        
        const pendingIds = new Set();
        pendingSnapshot1.forEach(doc => pendingIds.add(doc.id));
        pendingSnapshot2.forEach(doc => pendingIds.add(doc.id));
        const pendingCount = pendingIds.size;
        
        updateStatsUI(totalUsers, activeCount, pendingCount);
    } catch (error) {
        console.error('Error fetching user stats:', error);
        updateStatsUI(0, 0, 0);
    }
}

function updateStatsUI(total, active, pending) {
    const totalEl = document.getElementById('total-users-count');
    const activeEl = document.getElementById('active-users-count');
    const pendingEl = document.getElementById('pending-users-count');
    
    if (totalEl) totalEl.textContent = total.toLocaleString();
    if (activeEl) activeEl.textContent = active.toLocaleString();
    if (pendingEl) pendingEl.textContent = pending.toLocaleString();
}

async function loadUsers(page) {
    try {
        currentPage = page;
        const usersCollection = collection(db, 'users');
        
        let q;
        if (page === 1) {
            q = query(
                usersCollection,
                limit(usersPerPage)
            );
        } else {
            const cachedDoc = pageCache.get(page - 1);
            if (cachedDoc) {
                q = query(
                    usersCollection,
                    startAfter(cachedDoc),
                    limit(usersPerPage)
                );
            } else {
                console.error('Page cache miss, reloading from page 1');
                loadUsers(1);
                return;
            }
        }
        
        const snapshot = await getDocs(q);
        const users = [];
        
        snapshot.forEach((doc) => {
            users.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        if (snapshot.docs.length > 0) {
            firstVisibleDoc = snapshot.docs[0];
            lastVisibleDoc = snapshot.docs[snapshot.docs.length - 1];
            pageCache.set(page, lastVisibleDoc);
        }
        
        users.sort((a, b) => {
            const nameA = (a.displayName || a.name || a.email || '').toLowerCase();
            const nameB = (b.displayName || b.name || b.email || '').toLowerCase();
            return nameA.localeCompare(nameB);
        });
        
        renderUsers(users);
        updatePaginationUI();
    } catch (error) {
        console.error('Error loading users:', error);
        showEmptyState('Error loading users. Please check console.');
    }
}

function setupPaginationControls() {
    const prevBtn = document.getElementById('prev-page-btn');
    const nextBtn = document.getElementById('next-page-btn');
    
    if (prevBtn) {
        prevBtn.addEventListener('click', () => {
            if (currentPage > 1) {
                loadUsers(currentPage - 1);
            }
        });
    }
    
    if (nextBtn) {
        nextBtn.addEventListener('click', () => {
            const totalPages = Math.ceil(totalUsers / usersPerPage);
            if (currentPage < totalPages) {
                loadUsers(currentPage + 1);
            }
        });
    }
}

function updatePaginationUI() {
    const totalPages = Math.ceil(totalUsers / usersPerPage);
    const startIndex = (currentPage - 1) * usersPerPage + 1;
    const endIndex = Math.min(currentPage * usersPerPage, totalUsers);
    
    const paginationInfo = document.getElementById('pagination-info');
    if (paginationInfo) {
        paginationInfo.innerHTML = `Showing <span class="font-bold text-slate-800 dark:text-white">${startIndex}</span> to <span class="font-bold text-slate-800 dark:text-white">${endIndex}</span> of <span class="font-bold text-slate-800 dark:text-white">${totalUsers}</span> users`;
    }
    
    const prevBtn = document.getElementById('prev-page-btn');
    const nextBtn = document.getElementById('next-page-btn');
    
    if (prevBtn) {
        prevBtn.disabled = currentPage === 1;
    }
    
    if (nextBtn) {
        nextBtn.disabled = currentPage >= totalPages;
    }
    
    const pageNumbersContainer = document.getElementById('page-numbers');
    if (pageNumbersContainer) {
        pageNumbersContainer.innerHTML = '';
        
        const maxVisiblePages = 5;
        let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
        let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
        
        if (endPage - startPage < maxVisiblePages - 1) {
            startPage = Math.max(1, endPage - maxVisiblePages + 1);
        }
        
        for (let i = startPage; i <= endPage; i++) {
            const pageBtn = document.createElement('button');
            pageBtn.className = i === currentPage 
                ? 'w-8 h-8 flex items-center justify-center rounded-lg bg-primary text-white text-xs font-bold shadow-lg shadow-primary/20'
                : 'w-8 h-8 flex items-center justify-center rounded-lg border border-primary/10 text-neutral-warm hover:bg-primary/5 text-xs font-bold';
            pageBtn.textContent = i;
            pageBtn.addEventListener('click', () => loadUsers(i));
            pageNumbersContainer.appendChild(pageBtn);
        }
    }
}

function renderUsers(users) {
    const tbody = document.getElementById('users-table-body');
    const loadingState = document.getElementById('loading-state');
    const emptyState = document.getElementById('empty-state');
    
    if (!tbody) return;
    
    loadingState?.classList.add('hidden');
    
    if (users.length === 0) {
        emptyState?.classList.remove('hidden');
        return;
    }
    
    emptyState?.classList.add('hidden');
    
    const existingRows = tbody.querySelectorAll('tr:not(#loading-state):not(#empty-state)');
    existingRows.forEach(row => row.remove());
    
    users.forEach(user => {
        const row = createUserRow(user);
        tbody.appendChild(row);
    });
}

function createUserRow(user) {
    const tr = document.createElement('tr');
    tr.className = 'hover:bg-primary/5 transition-colors group';
    tr.dataset.userId = user.id;
    
    const displayName = user.displayName || user.name || 'Unknown User';
    const email = user.email || 'No email';
    const role = user.role || 'listener';
    const status = user.status || 'active';
    const avatar = user.photoURL || user.avatar || '';
    const lastActive = user.lastActive ? formatLastActive(user.lastActive) : 'Never';
    
    const roleColors = {
        admin: 'bg-purple-100 text-purple-600 dark:bg-purple-500/20 dark:text-purple-400',
        artist: 'bg-orange-100 text-orange-600 dark:bg-orange-500/20 dark:text-orange-400',
        curator: 'bg-blue-100 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400',
        listener: 'bg-gray-100 text-gray-600 dark:bg-gray-500/20 dark:text-gray-400'
    };
    
    const statusColors = {
        active: 'text-emerald-500',
        suspended: 'text-slate-400',
        pending: 'text-amber-500'
    };
    
    const statusDotColors = {
        active: 'bg-emerald-500',
        suspended: 'bg-slate-400',
        pending: 'bg-amber-500'
    };
    
    const initials = displayName.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2);
    
    tr.innerHTML = `
        <td class="px-6 py-4">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full ${avatar ? 'bg-primary/10' : 'bg-slate-200 text-slate-500'} flex items-center justify-center overflow-hidden ${!avatar ? 'text-sm font-bold' : ''}">
                    ${avatar ? `<img class="w-full h-full object-cover" src="${avatar}" alt="Avatar">` : initials}
                </div>
                <div class="font-bold text-slate-800 dark:text-white">${displayName}</div>
            </div>
        </td>
        <td class="px-6 py-4 text-neutral-warm">${email}</td>
        <td class="px-6 py-4">
            <span class="${roleColors[role] || roleColors.listener} px-2.5 py-1 rounded-lg text-xs font-semibold capitalize">${role}</span>
        </td>
        <td class="px-6 py-4 text-neutral-warm">${lastActive}</td>
        <td class="px-6 py-4">
            <span class="${statusColors[status] || statusColors.active} text-xs font-bold flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full ${statusDotColors[status] || statusDotColors.active}"></span>
                <span class="capitalize">${status}</span>
            </span>
        </td>
        <td class="px-6 py-4 text-right">
            <div class="relative inline-block">
                <button class="text-neutral-warm hover:text-primary p-1 transition-colors user-actions-btn" data-user-id="${user.id}">
                    <span class="material-icons text-lg">more_vert</span>
                </button>
                <div class="user-actions-menu hidden absolute right-0 mt-2 w-48 bg-white dark:bg-[#1a130d] rounded-xl shadow-lg border border-primary/10 py-2 z-10">
                    <button class="w-full px-4 py-2 text-left text-sm hover:bg-primary/5 flex items-center gap-2 ${status === 'suspended' ? 'text-emerald-600' : 'text-amber-600'}" onclick="toggleBanUser('${user.id}', '${status}')">
                        <span class="material-icons text-sm">${status === 'suspended' ? 'check_circle' : 'block'}</span>
                        ${status === 'suspended' ? 'Activate User' : 'Suspend User'}
                    </button>
                    <button class="w-full px-4 py-2 text-left text-sm hover:bg-primary/5 flex items-center gap-2 text-red-600" onclick="deleteUser('${user.id}', '${displayName}')">
                        <span class="material-icons text-sm">delete</span>
                        Delete User
                    </button>
                </div>
            </div>
        </td>
    `;
    
    const actionsBtn = tr.querySelector('.user-actions-btn');
    const actionsMenu = tr.querySelector('.user-actions-menu');
    
    actionsBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        document.querySelectorAll('.user-actions-menu').forEach(menu => {
            if (menu !== actionsMenu) menu.classList.add('hidden');
        });
        actionsMenu.classList.toggle('hidden');
    });
    
    document.addEventListener('click', () => {
        actionsMenu.classList.add('hidden');
    });
    
    return tr;
}

async function toggleBanUser(userId, currentStatus) {
    try {
        const newStatus = currentStatus === 'suspended' ? 'active' : 'suspended';
        const userRef = doc(db, 'users', userId);
        
        await updateDoc(userRef, {
            status: newStatus,
            updatedAt: new Date().toISOString()
        });
        
        console.log(`User ${userId} status updated to ${newStatus}`);
    } catch (error) {
        console.error('Error updating user status:', error);
        alert('Failed to update user status. Please try again.');
    }
}

async function deleteUser(userId, userName) {
    const confirmed = confirm(`Are you sure you want to delete user "${userName}"? This action cannot be undone.`);
    
    if (!confirmed) return;
    
    try {
        const userRef = doc(db, 'users', userId);
        await deleteDoc(userRef);
        
        console.log(`User ${userId} deleted successfully`);
    } catch (error) {
        console.error('Error deleting user:', error);
        alert('Failed to delete user. Please try again.');
    }
}

function formatLastActive(timestamp) {
    if (!timestamp) return 'Never';
    
    let date;
    if (timestamp.toDate) {
        date = timestamp.toDate();
    } else if (typeof timestamp === 'string') {
        date = new Date(timestamp);
    } else if (timestamp instanceof Date) {
        date = timestamp;
    } else {
        return 'Unknown';
    }
    
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min${diffMins > 1 ? 's' : ''} ago`;
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    
    return date.toLocaleDateString();
}

function showEmptyState(message = 'No users found') {
    const tbody = document.getElementById('users-table-body');
    const loadingState = document.getElementById('loading-state');
    const emptyState = document.getElementById('empty-state');
    
    if (!tbody) return;
    
    loadingState?.classList.add('hidden');
    
    if (emptyState) {
        emptyState.classList.remove('hidden');
        const messageEl = emptyState.querySelector('p');
        if (messageEl) messageEl.textContent = message;
    }
}

window.toggleBanUser = toggleBanUser;
window.deleteUser = deleteUser;

// ===== MUSIC MANAGEMENT FUNCTIONS =====

let allTracks = [];
let filteredTracks = [];

function initMusicManagement() {
    fetchTracks();
    setupTrackFilters();
}

async function fetchTracks() {
    try {
        const tracksCollection = collection(db, 'tracks');
        const snapshot = await getDocs(tracksCollection);
        
        allTracks = [];
        snapshot.forEach((doc) => {
            allTracks.push({
                id: doc.id,
                ...doc.data()
            });
        });
        
        filteredTracks = [...allTracks];
        renderTracks(filteredTracks);
    } catch (error) {
        console.error('Error fetching tracks:', error);
        showTracksEmptyState('Error loading tracks. Please check console.');
    }
}

function renderTracks(tracks) {
    const tbody = document.getElementById('tracks-table-body');
    const loadingState = document.getElementById('tracks-loading-state');
    const emptyState = document.getElementById('tracks-empty-state');
    
    if (!tbody) return;
    
    loadingState?.classList.add('hidden');
    
    if (tracks.length === 0) {
        emptyState?.classList.remove('hidden');
        return;
    }
    
    emptyState?.classList.add('hidden');
    
    const existingRows = tbody.querySelectorAll('tr:not(#tracks-loading-state):not(#tracks-empty-state)');
    existingRows.forEach(row => row.remove());
    
    tracks.forEach(track => {
        const row = createTrackRow(track);
        tbody.appendChild(row);
    });
}

function createTrackRow(track) {
    const tr = document.createElement('tr');
    tr.className = 'hover:bg-primary/5 transition-colors group';
    tr.dataset.trackId = track.id;
    
    const title = track.title || 'Untitled Track';
    const artist = track.artist || 'Unknown Artist';
    const genre = track.genre || 'unknown';
    const status = track.status || 'draft';
    const artwork = track.artworkUrl || '';
    const plays = track.plays || 0;
    const likes = track.likes || 0;
    
    const statusColors = {
        published: 'text-emerald-500 bg-emerald-500/10',
        draft: 'text-amber-500 bg-amber-500/10',
        flagged: 'text-red-500 bg-red-500/10'
    };
    
    const genreLabels = {
        lofi: 'Lofi Focus',
        acoustic: 'Acoustic',
        ambient: 'Ambient',
        cinematic: 'Cinematic'
    };
    
    tr.innerHTML = `
        <td class="px-6 py-4">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-lg overflow-hidden bg-primary/10 flex-shrink-0">
                    ${artwork ? `<img src="${artwork}" alt="${title}" class="w-full h-full object-cover">` : `<span class="material-icons text-primary text-2xl flex items-center justify-center w-full h-full">music_note</span>`}
                </div>
                <div>
                    <p class="font-bold text-slate-800 dark:text-white">${title}</p>
                    <p class="text-sm text-neutral-warm">${artist}</p>
                </div>
            </div>
        </td>
        <td class="px-6 py-4">
            <span class="bg-primary/10 text-primary px-2.5 py-1 rounded-lg text-xs font-semibold">${genreLabels[genre] || genre}</span>
        </td>
        <td class="px-6 py-4">
            <div class="flex items-center gap-4 text-xs text-neutral-warm">
                <div class="flex items-center gap-1">
                    <span class="material-icons text-sm">play_arrow</span>
                    <span>${plays.toLocaleString()}</span>
                </div>
                <div class="flex items-center gap-1">
                    <span class="material-icons text-sm">favorite</span>
                    <span>${likes.toLocaleString()}</span>
                </div>
            </div>
        </td>
        <td class="px-6 py-4">
            <span class="${statusColors[status] || statusColors.draft} px-2.5 py-1 rounded-lg text-xs font-semibold capitalize">${status}</span>
        </td>
        <td class="px-6 py-4 text-right">
            <div class="flex items-center justify-end gap-2">
                <button class="text-neutral-warm hover:text-primary p-2 transition-colors" title="Edit" onclick="editTrack('${track.id}')">
                    <span class="material-icons text-lg">edit</span>
                </button>
                <button class="text-neutral-warm hover:text-red-500 p-2 transition-colors" title="Delete" onclick="deleteTrack('${track.id}', '${title.replace(/'/g, "\\'")}')">
                    <span class="material-icons text-lg">delete</span>
                </button>
            </div>
        </td>
    `;
    
    return tr;
}

async function deleteTrack(trackId, trackTitle) {
    const confirmed = confirm(`Are you sure you want to delete "${trackTitle}"? This will also delete associated audio and artwork files. This action cannot be undone.`);
    
    if (!confirmed) return;
    
    try {
        const trackRef = doc(db, 'tracks', trackId);
        const trackDoc = await getDocs(query(collection(db, 'tracks'), where('__name__', '==', trackId)));
        
        let trackData = null;
        trackDoc.forEach(doc => {
            trackData = doc.data();
        });
        
        if (trackData) {
            if (trackData.audioUrl) {
                try {
                    const audioRef = ref(storage, `tracks/${trackId}/audio`);
                    await deleteObject(audioRef);
                } catch (err) {
                    console.warn('Audio file not found or already deleted:', err);
                }
            }
            
            if (trackData.artworkUrl) {
                try {
                    const artworkRef = ref(storage, `tracks/${trackId}/artwork`);
                    await deleteObject(artworkRef);
                } catch (err) {
                    console.warn('Artwork file not found or already deleted:', err);
                }
            }
        }
        
        await deleteDoc(trackRef);
        
        console.log(`Track ${trackId} deleted successfully`);
        
        await fetchTracks();
    } catch (error) {
        console.error('Error deleting track:', error);
        alert('Failed to delete track. Please try again.');
    }
}

function editTrack(trackId) {
    window.location.href = `add-track.html?edit=${trackId}`;
}

function setupTrackFilters() {
    const searchInput = document.getElementById('track-search-input');
    const genreFilter = document.getElementById('genre-filter');
    const statusFilter = document.getElementById('status-filter');
    
    if (searchInput) {
        searchInput.addEventListener('input', applyTrackFilters);
    }
    
    if (genreFilter) {
        genreFilter.addEventListener('change', applyTrackFilters);
    }
    
    if (statusFilter) {
        statusFilter.addEventListener('change', applyTrackFilters);
    }
}

function applyTrackFilters() {
    const searchInput = document.getElementById('track-search-input');
    const genreFilter = document.getElementById('genre-filter');
    const statusFilter = document.getElementById('status-filter');
    
    const searchTerm = searchInput?.value.toLowerCase() || '';
    const selectedGenre = genreFilter?.value || '';
    const selectedStatus = statusFilter?.value || '';
    
    filteredTracks = allTracks.filter(track => {
        const matchesSearch = !searchTerm || 
            (track.title || '').toLowerCase().includes(searchTerm) ||
            (track.artist || '').toLowerCase().includes(searchTerm) ||
            (track.genre || '').toLowerCase().includes(searchTerm);
        
        const matchesGenre = !selectedGenre || track.genre === selectedGenre;
        const matchesStatus = !selectedStatus || track.status === selectedStatus;
        
        return matchesSearch && matchesGenre && matchesStatus;
    });
    
    renderTracks(filteredTracks);
}

function showTracksEmptyState(message = 'No tracks found') {
    const tbody = document.getElementById('tracks-table-body');
    const loadingState = document.getElementById('tracks-loading-state');
    const emptyState = document.getElementById('tracks-empty-state');
    
    if (!tbody) return;
    
    loadingState?.classList.add('hidden');
    
    if (emptyState) {
        emptyState.classList.remove('hidden');
        const messageEl = emptyState.querySelector('p');
        if (messageEl) messageEl.textContent = message;
    }
}

window.deleteTrack = deleteTrack;
window.editTrack = editTrack;

// ===== TRACK WIZARD FUNCTIONS =====

let audioFile = null;
let artworkFile = null;

function initTrackWizard() {
    setupFileInputs();
    setupPublishButton();
    setupDraftButton();
}

function setupFileInputs() {
    const audioInput = document.getElementById('audio-file-input');
    const browseAudioBtn = document.getElementById('browse-audio-btn');
    const artworkInput = document.getElementById('artwork-file-input');
    const artworkContainer = document.getElementById('artwork-preview-container');
    
    if (browseAudioBtn && audioInput) {
        browseAudioBtn.addEventListener('click', () => {
            audioInput.click();
        });
        
        audioInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                audioFile = file;
                console.log('Audio file selected:', file.name);
                alert(`Audio file "${file.name}" selected successfully!`);
            }
        });
    }
    
    if (artworkContainer && artworkInput) {
        artworkContainer.addEventListener('click', () => {
            artworkInput.click();
        });
        
        artworkInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                artworkFile = file;
                
                const reader = new FileReader();
                reader.onload = (event) => {
                    const preview = document.getElementById('artwork-preview');
                    const placeholder = document.getElementById('artwork-placeholder');
                    
                    if (preview && placeholder) {
                        preview.src = event.target.result;
                        preview.classList.remove('hidden');
                        placeholder.classList.add('hidden');
                    }
                };
                reader.readAsDataURL(file);
            }
        });
    }
}

function setupPublishButton() {
    const publishBtn = document.getElementById('publish-track-btn');
    
    if (publishBtn) {
        publishBtn.addEventListener('click', () => {
            publishTrack('published');
        });
    }
}

function setupDraftButton() {
    const draftBtn = document.getElementById('save-draft-btn');
    
    if (draftBtn) {
        draftBtn.addEventListener('click', () => {
            publishTrack('draft');
        });
    }
}

async function publishTrack(status) {
    try {
        const title = document.getElementById('track-title')?.value;
        const artist = document.getElementById('track-artist')?.value;
        const genre = document.getElementById('track-genre')?.value;
        const releaseDate = document.getElementById('track-release-date')?.value;
        const isExplicit = document.getElementById('track-explicit')?.checked || false;
        const isPublic = document.getElementById('track-public')?.checked || false;
        
        if (!title || !artist || !genre) {
            alert('Please fill in all required fields (Title, Artist, Genre)');
            return;
        }
        
        if (!audioFile) {
            alert('Please upload an audio file');
            return;
        }
        
        if (!artworkFile) {
            alert('Please upload artwork');
            return;
        }
        
        const publishBtn = document.getElementById('publish-track-btn');
        const draftBtn = document.getElementById('save-draft-btn');
        
        if (publishBtn) publishBtn.disabled = true;
        if (draftBtn) draftBtn.disabled = true;
        
        if (publishBtn) publishBtn.textContent = 'Uploading...';
        
        const trackId = `track_${Date.now()}`;
        
        const audioRef = ref(storage, `tracks/${trackId}/audio`);
        await uploadBytes(audioRef, audioFile);
        const audioUrl = await getDownloadURL(audioRef);
        
        const artworkRef = ref(storage, `tracks/${trackId}/artwork`);
        await uploadBytes(artworkRef, artworkFile);
        const artworkUrl = await getDownloadURL(artworkRef);
        
        const trackData = {
            title,
            artist,
            genre,
            releaseDate: releaseDate || new Date().toISOString().split('T')[0],
            isExplicit,
            isPublic,
            status,
            audioUrl,
            artworkUrl,
            plays: 0,
            likes: 0,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
        
        await addDoc(collection(db, 'tracks'), trackData);
        
        alert(`Track ${status === 'published' ? 'published' : 'saved as draft'} successfully!`);
        
        window.location.href = 'music.html';
    } catch (error) {
        console.error('Error publishing track:', error);
        alert('Failed to publish track. Please try again.');
        
        const publishBtn = document.getElementById('publish-track-btn');
        const draftBtn = document.getElementById('save-draft-btn');
        
        if (publishBtn) {
            publishBtn.disabled = false;
            publishBtn.textContent = 'Publish Track';
        }
        if (draftBtn) draftBtn.disabled = false;
    }
}
