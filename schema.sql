(function () {
  'use strict';

  // ---------- Supabase client ----------
  if (!window.supabase) {
    console.error('Supabase SDK belum termuat. Periksa koneksi internet / urutan <script>.');
  }
  const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const configured =
    !SUPABASE_URL.includes('GANTI-DENGAN') && !SUPABASE_ANON_KEY.includes('GANTI-DENGAN');

  const state = {
    view: 'home',
    category: 'all',
    search: '',
    projects: [],
    currentProject: null
  };

  // ---------- Elements ----------
  const els = {
    navLinks: document.querySelectorAll('.nav-link'),
    navToggle: document.getElementById('navToggle'),
    navLinksList: document.getElementById('navLinks'),
    viewFeed: document.getElementById('view-feed'),
    viewDetail: document.getElementById('view-detail'),
    viewUpload: document.getElementById('view-upload'),
    hero: document.getElementById('hero'),
    projectGrid: document.getElementById('projectGrid'),
    emptyState: document.getElementById('emptyState'),
    statusMsg: document.getElementById('statusMsg'),
    filterBar: document.getElementById('filterBar'),
    searchInput: document.getElementById('searchInput'),
    detailContent: document.getElementById('detailContent'),
    backFromDetail: document.getElementById('backFromDetail'),
    uploadForm: document.getElementById('uploadForm'),
    uploadMsg: document.getElementById('uploadMsg'),
    submitBtn: document.getElementById('submitBtn')
  };

  const iconSvg = `<svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#4fd1c5" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>`;

  function escapeHtml(str) {
    if (!str) return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function timeAgo(dateStr) {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'baru saja';
    if (mins < 60) return `${mins} menit lalu`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs} jam lalu`;
    const days = Math.floor(hrs / 24);
    if (days < 30) return `${days} hari lalu`;
    return new Date(dateStr).toLocaleDateString('id-ID');
  }

  function publicUrl(path) {
    if (!path) return null;
    const { data } = sb.storage.from(STORAGE_BUCKET).getPublicUrl(path);
    return data ? data.publicUrl : null;
  }

  // Ubah baris dari Supabase (snake_case) jadi bentuk yang dipakai UI
  function normalizeProject(row) {
    return {
      id: row.id,
      name: row.name,
      title: row.title,
      category: row.category,
      description: row.description,
      code: row.code || '',
      videoUrl: row.video_url || '',
      linkUrl: row.link_url || '',
      file: row.file_path
        ? { url: publicUrl(row.file_path), originalName: row.file_original_name }
        : null,
      image: row.image_path ? { url: publicUrl(row.image_path) } : null,
      createdAt: row.created_at
    };
  }

  // ---------- View switching ----------
  function setView(view) {
    state.view = view;
    els.viewFeed.classList.toggle('hidden', view !== 'home');
    els.viewDetail.classList.toggle('hidden', view !== 'detail');
    els.viewUpload.classList.toggle('hidden', view !== 'upload');
    els.hero.classList.toggle('hidden', view !== 'home');

    els.navLinks.forEach((a) => {
      a.classList.toggle('active', a.dataset.view === view && view !== 'detail');
    });
    els.navLinksList.classList.remove('open');
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (view === 'home') loadProjects();
  }

  document.querySelectorAll('[data-view]').forEach((el) => {
    el.addEventListener('click', (e) => {
      e.preventDefault();
      const v = el.dataset.view;
      if (v === 'arduino' || v === 'robotik') {
        state.category = v;
        setView('home');
        syncFilterButtons();
      } else {
        setView(v);
      }
    });
  });

  els.navToggle.addEventListener('click', () => {
    els.navLinksList.classList.toggle('open');
  });

  els.backFromDetail.addEventListener('click', () => setView('home'));

  function syncFilterButtons() {
    document.querySelectorAll('.filter-btn').forEach((b) => {
      b.classList.toggle('active', b.dataset.filter === state.category);
    });
  }

  // ---------- Status messages ----------
  function showStatus(el, text, type) {
    el.textContent = text;
    el.className = 'status-msg ' + (type || '');
    el.classList.remove('hidden');
  }
  function hideStatus(el) {
    el.classList.add('hidden');
  }

  // ---------- Load & render feed ----------
  async function loadProjects() {
    if (!configured) {
      showStatus(
        els.statusMsg,
        'Supabase belum dikonfigurasi. Isi SUPABASE_URL dan SUPABASE_ANON_KEY di config.js terlebih dahulu (lihat README.md).',
        'error'
      );
      els.projectGrid.innerHTML = '';
      return;
    }

    showStatus(els.statusMsg, 'Memuat proyek...', 'loading');
    els.projectGrid.innerHTML = '';
    els.emptyState.classList.add('hidden');

    try {
      let query = sb.from('projects').select('*').order('created_at', { ascending: false });

      if (state.category !== 'all') {
        query = query.eq('category', state.category);
      }
      if (state.search) {
        // Cari di judul ATAU deskripsi
        query = query.or(`title.ilike.%${state.search}%,description.ilike.%${state.search}%`);
      }

      const { data, error } = await query;
      if (error) throw error;

      state.projects = (data || []).map(normalizeProject);
      hideStatus(els.statusMsg);
      renderGrid();
    } catch (err) {
      showStatus(els.statusMsg, 'Gagal memuat proyek: ' + err.message, 'error');
    }
  }

  function renderGrid() {
    if (state.projects.length === 0) {
      els.projectGrid.innerHTML = '';
      els.emptyState.classList.remove('hidden');
      return;
    }
    els.emptyState.classList.add('hidden');
    els.projectGrid.innerHTML = state.projects
      .map(
        (p) => `
      <div class="card" data-id="${p.id}">
        <div class="card-photo">
          <span class="card-tag">${p.category === 'arduino' ? 'Arduino' : 'Robotik'}</span>
          ${
            p.image
              ? `<img src="${p.image.url}" alt="${escapeHtml(p.title)}">`
              : `<span class="ph-icon">${iconSvg}</span>`
          }
        </div>
        <div class="card-body">
          <h3>${escapeHtml(p.title)}</h3>
          <p>${escapeHtml(p.description)}</p>
          <div class="card-meta">
            <span>oleh ${escapeHtml(p.name || 'Anonim')}</span>
            <span>${timeAgo(p.createdAt)}</span>
          </div>
          <div class="card-badges">
            ${p.code ? '<span class="badge">Kode</span>' : ''}
            ${p.file ? '<span class="badge">File</span>' : ''}
            ${p.videoUrl ? '<span class="badge">Video</span>' : ''}
            ${p.linkUrl ? '<span class="badge">Link</span>' : ''}
          </div>
        </div>
      </div>`
      )
      .join('');

    els.projectGrid.querySelectorAll('.card').forEach((card) => {
      card.addEventListener('click', () => openDetail(card.dataset.id));
    });
  }

  els.filterBar.addEventListener('click', (e) => {
    if (!e.target.classList.contains('filter-btn')) return;
    state.category = e.target.dataset.filter;
    syncFilterButtons();
    loadProjects();
  });

  let searchTimeout;
  els.searchInput.addEventListener('input', (e) => {
    clearTimeout(searchTimeout);
    state.search = e.target.value.trim();
    searchTimeout = setTimeout(loadProjects, 350);
  });

  // ---------- Detail view ----------
  function toEmbedUrl(url) {
    if (!url) return null;
    try {
      const u = new URL(url);
      if (u.hostname.includes('youtube.com') && u.searchParams.get('v')) {
        return `https://www.youtube.com/embed/${u.searchParams.get('v')}`;
      }
      if (u.hostname === 'youtu.be') {
        return `https://www.youtube.com/embed${u.pathname}`;
      }
      return null;
    } catch {
      return null;
    }
  }

  async function openDetail(id) {
    setView('detail');
    els.detailContent.innerHTML = '<p style="color:var(--ink-dim);">Memuat detail proyek...</p>';
    try {
      const { data, error } = await sb.from('projects').select('*').eq('id', id).single();
      if (error) throw error;
      renderDetail(normalizeProject(data));
    } catch (err) {
      els.detailContent.innerHTML = `<p style="color:var(--danger);">Gagal memuat proyek: ${escapeHtml(err.message)}</p>`;
    }
  }

  function renderDetail(p) {
    state.currentProject = p;
    const embed = toEmbedUrl(p.videoUrl);

    els.detailContent.innerHTML = `
      <div class="detail">
        <div class="detail-head">
          <div>
            <h2>${escapeHtml(p.title)}</h2>
            <div class="detail-meta">oleh ${escapeHtml(p.name || 'Anonim')} · ${timeAgo(p.createdAt)}</div>
          </div>
          <span class="card-tag" style="position:static;">${p.category === 'arduino' ? 'Arduino' : 'Robotik'}</span>
        </div>

        ${p.image ? `<img class="detail-photo" src="${p.image.url}" alt="${escapeHtml(p.title)}">` : ''}
        ${
          embed
            ? `<div class="video-embed"><iframe src="${embed}" title="Video ${escapeHtml(p.title)}" allowfullscreen></iframe></div>`
            : ''
        }

        <div class="detail-cols">
          <div>
            <h4>Penjelasan</h4>
            <p class="desc">${escapeHtml(p.description)}</p>

            ${
              p.code
                ? `<h4>Source Code</h4><pre><code>${escapeHtml(p.code)}</code></pre>`
                : ''
            }
          </div>
          <div>
            <h4>Sumber Daya</h4>
            <div class="resource-links">
              ${
                p.file
                  ? `<a class="resource-link" href="${p.file.url}" target="_blank" rel="noopener">📦 Unduh file: ${escapeHtml(p.file.originalName || 'file')}</a>`
                  : ''
              }
              ${
                p.linkUrl && !embed
                  ? `<a class="resource-link" href="${escapeHtml(p.linkUrl)}" target="_blank" rel="noopener">🔗 ${escapeHtml(p.linkUrl)}</a>`
                  : ''
              }
              ${
                p.videoUrl && !embed
                  ? `<a class="resource-link" href="${escapeHtml(p.videoUrl)}" target="_blank" rel="noopener">🎬 ${escapeHtml(p.videoUrl)}</a>`
                  : ''
              }
              ${
                !p.file && !p.linkUrl && !p.videoUrl
                  ? `<p style="color:var(--ink-dim); font-size:0.85rem;">Tidak ada file atau link tambahan untuk proyek ini.</p>`
                  : ''
              }
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // ---------- Upload form ----------
  function sanitizeFileName(name) {
    return name.replace(/[^a-zA-Z0-9.\-_]/g, '_').slice(0, 60);
  }

  async function uploadToStorage(file) {
    const path = `${Date.now()}-${crypto.randomUUID()}-${sanitizeFileName(file.name)}`;
    const { error } = await sb.storage.from(STORAGE_BUCKET).upload(path, file, {
      cacheControl: '3600',
      upsert: false
    });
    if (error) throw error;
    return path;
  }

  els.uploadForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    hideStatus(els.uploadMsg);

    if (!configured) {
      showStatus(
        els.uploadMsg,
        'Supabase belum dikonfigurasi. Isi config.js terlebih dahulu (lihat README.md).',
        'error'
      );
      return;
    }

    els.submitBtn.disabled = true;
    els.submitBtn.textContent = 'Mengunggah...';

    try {
      const form = els.uploadForm;
      const name = form.name.value.trim();
      const title = form.title.value.trim();
      const category = form.category.value;
      const description = form.description.value.trim();
      const code = form.code.value;
      const videoUrl = form.videoUrl.value.trim();
      const linkUrl = form.linkUrl.value.trim();
      const fileInput = document.getElementById('f-file');
      const imageInput = document.getElementById('f-image');

      if (!title) throw new Error('Judul proyek wajib diisi.');
      if (!category) throw new Error('Kategori wajib dipilih.');
      if (!description) throw new Error('Penjelasan proyek wajib diisi.');

      const MAX_MB = 20;
      let filePath = null;
      let fileOriginalName = null;
      let imagePath = null;

      if (fileInput.files[0]) {
        const f = fileInput.files[0];
        if (f.size > MAX_MB * 1024 * 1024) throw new Error(`Ukuran file maksimal ${MAX_MB}MB.`);
        showStatus(els.uploadMsg, 'Mengunggah file...', 'loading');
        filePath = await uploadToStorage(f);
        fileOriginalName = f.name;
      }
      if (imageInput.files[0]) {
        const img = imageInput.files[0];
        if (img.size > MAX_MB * 1024 * 1024) throw new Error(`Ukuran foto maksimal ${MAX_MB}MB.`);
        showStatus(els.uploadMsg, 'Mengunggah foto...', 'loading');
        imagePath = await uploadToStorage(img);
      }

      showStatus(els.uploadMsg, 'Menyimpan data proyek...', 'loading');
      const { data, error } = await sb
        .from('projects')
        .insert([
          {
            name: name || 'Anonim',
            title,
            category,
            description,
            code: code || null,
            video_url: videoUrl || null,
            link_url: linkUrl || null,
            file_path: filePath,
            file_original_name: fileOriginalName,
            image_path: imagePath
          }
        ])
        .select()
        .single();

      if (error) throw error;

      showStatus(els.uploadMsg, 'Proyek berhasil diunggah!', 'success');
      form.reset();
      state.category = data.category;

      setTimeout(() => {
        syncFilterButtons();
        setView('home');
      }, 700);
    } catch (err) {
      showStatus(els.uploadMsg, 'Gagal upload: ' + err.message, 'error');
    } finally {
      els.submitBtn.disabled = false;
      els.submitBtn.textContent = 'Upload Proyek';
    }
  });

  // ---------- Init ----------
  document.getElementById('year').textContent = new Date().getFullYear();
  setView('home');
})();
