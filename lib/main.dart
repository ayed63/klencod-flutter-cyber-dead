if (d.type === "username") {
    const rows = (d.results || []).map((r) => {
      const st = r.exists === true ? "✅ موجود"
        : r.exists === false ? "❌ غير موجود" : "⚠️ غير محدد";
      const ex = r.extra || {};
      return '<tr class="' + (r.exists ? "hit" : "miss") + '">' +
        '<td>' + esc(r.label_ar || r.platform) + '</td>' +
        '<td class="mono">@' + esc(r.username) + '</td>' +
        '<td>' + esc(r.display_name) + '</td>' +
        '<td>' + st + '</td>' +
        '<td><span class="badge ' + esc(r.confidence) + '">' + esc(r.confidence) + '</span></td>' +
        '<td class="mono">' + esc(Object.keys(ex).length ? JSON.stringify(ex) : "—") + '</td>' +
        '<td><a href="' + esc(r.profile_url) + '" target="_blank" rel="noopener">فتح</a></td></tr>';
    }).join("");
    body =
      '<section class="kpis">' +
      '<div class="kpi"><b>' + ((d.results || []).filter((r) => r.exists === true).length) +
        '</b><span>منصات مؤكدة</span></div>' +
      '<div class="kpi"><b>' + (d.results || []).length + '</b><span>منصات مفحوصة</span></div>' +
      '<div class="kpi"><b>' + esc(d.query) + '</b><span>اليوزر</span></div></section>' +
      '<table><thead><tr><th>المنصة</th><th>اليوزر</th><th>الاسم</th><th>الحالة</th>' +
      '<th>الثقة</th><th>تفاصيل</th><th>الرابط</th></tr></thead><tbody>' + rows + '</tbody></table>';
  } else {
    const i = d.info || {}, links = d.messengers || {};
    const infoRows = Object.keys(i).map((k) =>
      '<dt>' + esc(k) + '</dt><dd class="mono">' + esc(i[k]) + '</dd>').join("");
    const linkRows = Object.keys(links).map((k) =>
      '<dt>' + esc(k) + '</dt><dd><a href="' + esc(links[k]) +
      '" target="_blank" rel="noopener">' + esc(links[k]) + '</a></dd>').join("");
    const dorkRows = (d.dorks || []).map((x) =>
      '<li><a href="' + esc(x.url) + '" target="_blank" rel="noopener">' +
      esc(x.query) + '</a></li>').join("");
    const waState = d.whatsapp && d.whatsapp.exists === true ? "✅ مسجّل"
      : d.whatsapp && d.whatsapp.exists === false ? "❌ غير مسجّل" : "⚠️ غير محدد";
    body =
      '<section class="kpis">' +
      '<div class="kpi"><b>' + esc(i.region) + '</b><span>الدولة</span></div>' +
      '<div class="kpi"><b>' + esc(i.carrier) + '</b><span>المشغّل</span></div>' +
      '<div class="kpi"><b>' + (i.valid ? "صالح" : "غير صالح") + '</b><span>التحقق</span></div>' +
      '</section>' +
      '<div class="cols">' +
      '<div class="panel"><h2>بيانات الرقم</h2><dl class="kv">' + infoRows + '</dl></div>' +
      '<div class="panel"><h2>تطبيقات المراسلة</h2><dl class="kv">' + linkRows +
      '<dt>WhatsApp</dt><dd>' + waState + '</dd></dl></div></div>' +
      '<div class="panel"><h2>Google Dorks (' + (d.dorks || []).length + ')</h2>' +
      '<ul class="dorks">' + dorkRows + '</ul></div>';
  }

  return "<!doctype html>\n<html lang=\"ar\" dir=\"rtl\"><head>\n" +
    '<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">\n' +
    "<title>" + title + "</title>\n<style>\n" + css + "\n</style>\n</head><body>\n" +
    "<header><h1>" + title + "</h1>" +
    '<div class="meta">أُنشئ: ' + gen + " · النوع: " + d.type.toUpperCase() +
    " · الوضع: " + (d.mode || "local") + "</div></header>\n" +
    body +
    "\n<footer>تم التوليد آليًا — استخدم النتائج ضمن نطاق مُصرّح به فقط.</footer>\n" +
    "</body></html>";
}

/* عرض التقرير داخل إطار المعاينة */
function buildReportPane(d) {
  const html = buildReport(d);
  const blob = new Blob([html], { type: "text/html" });
  const url = URL.createObjectURL(blob);
  $("#preview").src = url;
  $("#repInfo").textContent = d.query + " · " + new Date().toLocaleTimeString("ar-EG");
  LAST.reportUrl = url;
  LAST.reportHtml = html;
}

$("#dlReport").addEventListener("click", () => {
  if (!LAST) return log("ابحث أولاً", "warn");
  download("report.html", LAST.reportHtml || buildReport(LAST.data));
});
$("#openWindow").addEventListener("click", () => {
  if (!LAST) return log("ابحث أولاً", "warn");
  const w = window.open("", "_blank");
  if (w) { w.document.write(LAST.reportHtml || buildReport(LAST.data)); w.document.close(); }
});
$("#printReport").addEventListener("click", () => {
  if (!LAST) return log("ابحث أولاً", "warn");
  const f = $("#preview");
  try { f.contentWindow.print(); } catch (e) { $("#openWindow").click(); }
});

/* ---------- تنزيل عام ---------- */
function download(name, content) {
  const blob = content instanceof Blob ? content
    : new Blob([content], { type: "text/plain;charset=utf-8" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 4000);
}

/* ---------- عارض الكود ---------- */
const FILES = [
  { id: "py-main",      name: "backend/main.py",              lang: "Python" },
  { id: "report-tpl",   name: "backend/templates/report.html", lang: "Jinja2" },
  { id: "app-js",       name: "backend/static/app.js",         lang: "JavaScript" },
  { id: "app-css",      name: "backend/static/app.css",        lang: "CSS" },
  { id: "report-css",   name: "backend/static/report.css",     lang: "CSS" },
  { id: "manifest",     name: "android/.../AndroidManifest.xml", lang: "XML" },
  { id: "kt-main",      name: "android/.../MainActivity.kt",   lang: "Kotlin" },
  { id: "kt-bridge",    name: "android/.../NativeBridge.kt",   lang: "Kotlin" },
  { id: "kt-notif",     name: "android/.../NotifListener.kt",  lang: "Kotlin" },
  { id: "kt-capture",   name: "android/.../SilentCapture.kt",  lang: "Kotlin" }
];
let curFile = null;
let curIdx = 0;

function buildFileChips() {
  $("#fileChips").innerHTML = FILES.map((f, i) =>
    '<div class="chip' + (i === 0 ? " on" : "") + '" data-i="' + i + '">' +
    f.lang + "</div>").join("");
  $$("#fileChips .chip").forEach((c) => c.addEventListener("click", () => {
    $$("#fileChips .chip").forEach((x) => x.classList.remove("on"));
    c.classList.add("on");
    showFile(Number(c.dataset.i));
  }));
  showFile(0);
}

function showFile(i) {
  curIdx = i;
  curFile = FILES[i];
  const text = src(curFile.id);
  $("#curName").textContent = curFile.name;
  $("#curLines").textContent = text.split("\n").length + " سطر · " +
    Math.round(text.length / 1024) + "KB";
  $("#codeView").textContent = text;
}

$("#copyFile").addEventListener("click", () => {
  const text = src(curFile.id);
  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(
      () => log("تم نسخ " + curFile.name),
      () => log("فشل النسخ — انسخ يدويًا", "warn"));
  } else log("النسخ غير مدعوم هنا", "warn");
});

$("#dlFile").addEventListener("click", () => {
  download(curFile.name.split("/").pop(), src(curFile.id));
  log("تم تنزيل " + curFile.name);
});

$("#openRep").addEventListener("click", () => {
  $$("#tabs .tab").forEach((x) => x.classList.remove("on"));
  $$('#tabs .tab[data-tab="report"]')[0].classList.add("on");
  $$(".tabpane").forEach((p) => p.classList.remove("active"));
  document.getElementById("tab-report").classList.add("active");
});

/* ---------- أحداث البحث والفلاتر ---------- */
$("#go").addEventListener("click", doSearch);
$("#q").addEventListener("keydown", (e) => { if (e.key === "Enter") doSearch(); });
$$("#chips .chip").forEach((c) => c.addEventListener("click", () => {
  $$("#chips .chip").forEach((x) => x.classList.remove("on"));
  c.classList.add("on");
  filter = c.dataset.p;
  if (LAST && !LAST.isPhone) renderUser(LAST.data);
}));

/* ---------- إشعار دفع من جسر Kotlin (إن وُجد) ---------- */
document.addEventListener("DOMContentLoaded", () => {
  buildFileChips();
  const pre = bridge("lastSearchQuery");
  if (pre) $("#q").value = pre;
  log("جاهز — الوضع " + (CFG.base ? "خادم" : "محلي"));
  if (window.Native) log("جسر Kotlin متصل — الصلاحيات الأصلية نشطة");
});
</script>
</body>
</html>