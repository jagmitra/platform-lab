const page = location.pathname.split('/').pop() || 'index.html';
document.querySelectorAll('nav a').forEach(a => {
  if (a.getAttribute('href') === page) a.classList.add('active');
});

fetch('env.json')
  .then(r => r.json())
  .then(cfg => {
    document.body.classList.add('env-' + cfg.env);
    document.querySelectorAll('[data-env]').forEach(el => {
      const value = cfg[el.dataset.env];
      if (value !== undefined) el.textContent = value;
    });
    document.title = document.title + ' · ' + cfg.label;
  })
  .catch(() => {});
