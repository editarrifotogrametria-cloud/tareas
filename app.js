// Panel GNSS.AI K922 COM1 único
// Aquí solo existe un puerto físico: COM1 (GNSS_RXD1 / GNSS_TXD1).
// El panel construye un JSON que tu backend debe traducir a comandos reales.

const CONSTELLATIONS = [
  "GPS",
  "BDS-2",
  "BDS-3",
  "GLONASS",
  "GALILEO",
  "QZSS",
  "SBAS"
];

const SERIAL_BAUDRATES = [9600, 19200, 38400, 57600, 115200, 230400];

const RATES_POSITION = [1, 2, 5, 10, 20];
const RATES_IMU = [1, 2, 5, 10, 20, 50];

const NMEA_TALKERS = ["GN", "GP"];
const NMEA_MESSAGES = [
  "GGA", "GSA", "GSV", "GLL", "GST", "HDT", "RMC", "VTG", "ZDA"
];

const RTCM_MESSAGES = [
  "1004","1005","1006","1012",
  "1033","1074","1084","1094","1124",
  "1230","4078"
];

let socket = null;

// ===== Utilidades UI =====
function logStatus(msg) {
  const el = document.getElementById("statusLog");
  if (!el) return;
  const ts = new Date().toISOString().slice(11, 19);
  el.textContent += `[${ts}] ${msg}\n`;
  el.scrollTop = el.scrollHeight;
}

function setConnStatus(connected) {
  const badge = document.getElementById("connStatus");
  if (!badge) return;
  if (connected) {
    badge.textContent = "Conectado";
    badge.classList.remove("badge--danger");
    badge.classList.add("badge--success");
  } else {
    badge.textContent = "Desconectado";
    badge.classList.remove("badge--success");
    badge.classList.add("badge--danger");
  }
}

function fillSelect(id, items, { valueKey, labelKey } = {}) {
  const el = document.getElementById(id);
  if (!el) return;
  el.innerHTML = "";
  items.forEach((item) => {
    const opt = document.createElement("option");
    if (typeof item === "object") {
      opt.value = item[valueKey || "value"];
      opt.textContent = item[labelKey || "label"];
    } else {
      opt.value = item;
      opt.textContent = item;
    }
    el.appendChild(opt);
  });
}

function addPills(containerId, values) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";
  values.forEach((value) => {
    const label = document.createElement("label");
    label.className = "pill";
    const input = document.createElement("input");
    input.type = "checkbox";
    input.value = value;
    const span = document.createElement("span");
    span.textContent = value;
    label.appendChild(input);
    label.appendChild(span);
    container.appendChild(label);
  });
}

function getCheckedValues(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return [];
  return Array.from(container.querySelectorAll("input[type=checkbox]:checked")).map(
    (el) => el.value
  );
}

// ===== Tabs =====
function initTabs() {
  const buttons = document.querySelectorAll(".nav-btn");
  const panels = {
    status: document.getElementById("panel-status"),
    connection: document.getElementById("panel-connection"),
    gnss: document.getElementById("panel-gnss"),
    nmea: document.getElementById("panel-nmea"),
    imu: document.getElementById("panel-imu"),
    config: document.getElementById("panel-config")
  };

  buttons.forEach((btn) => {
    btn.addEventListener("click", () => {
      buttons.forEach((b) => b.classList.remove("nav-btn--active"));
      btn.classList.add("nav-btn--active");
      const target = btn.getAttribute("data-panel");
      Object.entries(panels).forEach(([key, panel]) => {
        if (!panel) return;
        panel.classList.toggle("panel--active", key === target);
      });
    });
  });
}

// ===== Inicialización =====
function initUI() {
  // Baudrate COM1
  fillSelect(
    "serialBaud",
    SERIAL_BAUDRATES.map((b) => ({ value: b, label: `${b} bps` })),
    { valueKey: "value", labelKey: "label" }
  );

  // Constelaciones GNSS
  addPills("gnssConstellations", CONSTELLATIONS);

  // Frecuencia RTK
  fillSelect(
    "rtkRate",
    RATES_POSITION.map((r) => ({ value: r, label: `${r} Hz` })),
    { valueKey: "value", labelKey: "label" }
  );

  // RTCM (modo base)
  addPills("rtcmMessages", RTCM_MESSAGES);

  // NMEA
  fillSelect("nmeaTalker", NMEA_TALKERS);
  fillSelect(
    "nmeaRate",
    RATES_POSITION.map((r) => ({ value: r, label: `${r} Hz` })),
    { valueKey: "value", labelKey: "label" }
  );
  addPills("nmeaMessages", NMEA_MESSAGES);

  // IMU
  fillSelect(
    "imuRate",
    RATES_IMU.map((r) => ({ value: r, label: `${r} Hz` })),
    { valueKey: "value", labelKey: "label" }
  );

  // Botones
  document.getElementById("btnConnect")?.addEventListener("click", connectBackend);
  document.getElementById("btnRequestStatus")?.addEventListener("click", sendStatusRequest);
  document.getElementById("btnExportJson")?.addEventListener("click", exportConfigJson);
  document.getElementById("fileImportJson")?.addEventListener("change", importConfigJson);
  document.getElementById("btnApplyConfig")?.addEventListener("click", sendApplyConfig);

  logStatus("UI inicializada (K922 COM1 único).");
}

// ===== WebSocket =====
function connectBackend() {
  const url = document.getElementById("backendUrl")?.value.trim();
  if (!url) {
    alert("Ingresa la URL del backend WebSocket.");
    return;
  }
  if (socket) {
    socket.close();
    socket = null;
  }
  try {
    socket = new WebSocket(url);
  } catch (e) {
    console.error(e);
    alert("No se pudo crear el WebSocket.");
    return;
  }
  logStatus(`Conectando a ${url} ...`);

  socket.onopen = () => {
    logStatus("WebSocket conectado.");
    setConnStatus(true);
    socket.send(JSON.stringify({ type: "hello", source: "gnssai-k922-com1-panel" }));
  };

  socket.onmessage = (event) => {
    logStatus("RX: " + event.data);
    try {
      const msg = JSON.parse(event.data);
      if (msg.type === "k922Status") {
        updateStatusFromBackend(msg.payload);
      }
    } catch (e) {
      // Texto bruto (NMEA, etc.), lo dejamos solo en el log.
    }
  };

  socket.onerror = (err) => {
    console.error(err);
    logStatus("Error en WebSocket.");
  };

  socket.onclose = () => {
    logStatus("WebSocket cerrado.");
    setConnStatus(false);
  };
}

function sendStatusRequest() {
  if (!socket || socket.readyState !== WebSocket.OPEN) {
    logStatus("No conectado, no se puede pedir estado.");
    return;
  }
  socket.send(JSON.stringify({ type: "getK922Status" }));
  logStatus("TX: getK922Status");
}

function updateStatusFromBackend(st) {
  if (!st) return;
  const setText = (id, value) => {
    const el = document.getElementById(id);
    if (el) el.textContent = value ?? "—";
  };
  setText("statMode", st.mode ?? "—");
  setText("statSats", st.satsUsed ?? "—");
  setText("statRtk", st.solution ?? "—");
  setText("statLat", st.lat?.toFixed ? st.lat.toFixed(8) : st.lat ?? "—");
  setText("statLon", st.lon?.toFixed ? st.lon.toFixed(8) : st.lon ?? "—");
  setText(
    "statH",
    st.hEllipsoidal?.toFixed ? `${st.hEllipsoidal.toFixed(3)} m` : st.hEllipsoidal ?? "—"
  );
  setText(
    "statVel",
    st.velocity?.toFixed ? `${st.velocity.toFixed(3)} m/s` : st.velocity ?? "—"
  );
  setText(
    "statHeading",
    st.heading?.toFixed ? `${st.heading.toFixed(2)} °` : st.heading ?? "—"
  );
  const pitchRoll =
    st.pitch != null && st.roll != null
      ? `${st.pitch.toFixed(2)}° / ${st.roll.toFixed(2)}°`
      : "—";
  setText("statPitchRoll", pitchRoll);
}

// ===== Config =====
function collectConfig() {
  const connection = {
    backendUrl: document.getElementById("backendUrl")?.value.trim() || "",
    transportType: document.getElementById("transportType")?.value || "serial",
    serialPort: document.getElementById("serialPort")?.value.trim() || "/dev/ttyS0",
    serialBaud: Number(document.getElementById("serialBaud")?.value || 115200),
    tcpPort: Number(document.getElementById("tcpPort")?.value || 7001)
  };

  const com1 = {
    role: document.getElementById("com1Role")?.value || "nmea_out"
  };

  const gnss = {
    constellationsEnabled: getCheckedValues("gnssConstellations"),
    mode: document.getElementById("rtkMode")?.value || "standalone",
    rateHz: Number(document.getElementById("rtkRate")?.value || 5),
    baselineKm: Number(document.getElementById("rtkBaseline")?.value || 10),
    corrIn: {
      source: document.getElementById("corrInSource")?.value || "none",
      format: document.getElementById("corrInFormat")?.value || "RTCM3"
    },
    rtcmBaseMessages: getCheckedValues("rtcmMessages")
  };

  const nmea = {
    talker: document.getElementById("nmeaTalker")?.value || "GN",
    baseRateHz: Number(document.getElementById("nmeaRate")?.value || 1),
    messages: getCheckedValues("nmeaMessages")
  };

  const imu = {
    enabled: document.getElementById("imuEnabled")?.checked ?? true,
    rateHz: Number(document.getElementById("imuRate")?.value || 5),
    insFusion: {
      priority: document.getElementById("insPriority")?.value || "prefer_gnss",
      maxGapNoGnssSec: Number(document.getElementById("insMaxGap")?.value || 30)
    }
  };

  return {
    device: "K922",
    version: 1,
    com: {
      singlePort: "COM1",
      com1
    },
    connection,
    gnss,
    nmea,
    imu
  };
}

function applyConfigToUI(cfg) {
  if (!cfg) return;
  const setVal = (id, v) => {
    const el = document.getElementById(id);
    if (el && v !== undefined && v !== null) el.value = v;
  };

  if (cfg.connection) {
    const c = cfg.connection;
    setVal("backendUrl", c.backendUrl);
    setVal("transportType", c.transportType);
    setVal("serialPort", c.serialPort);
    setVal("serialBaud", c.serialBaud);
    setVal("tcpPort", c.tcpPort);
  }

  if (cfg.com && cfg.com.com1) {
    const p = cfg.com.com1;
    setVal("com1Role", p.role);
  }

  if (cfg.gnss) {
    const g = cfg.gnss;
    setVal("rtkMode", g.mode);
    setVal("rtkRate", g.rateHz);
    setVal("rtkBaseline", g.baselineKm);
    setVal("corrInSource", g.corrIn?.source);
    setVal("corrInFormat", g.corrIn?.format);
    if (Array.isArray(g.constellationsEnabled)) {
      const cont = document.getElementById("gnssConstellations");
      if (cont) {
        Array.from(cont.querySelectorAll("input[type=checkbox]")).forEach((inp) => {
          inp.checked = g.constellationsEnabled.includes(inp.value);
        });
      }
    }
    if (Array.isArray(g.rtcmBaseMessages)) {
      const cont = document.getElementById("rtcmMessages");
      if (cont) {
        Array.from(cont.querySelectorAll("input[type=checkbox]")).forEach((inp) => {
          inp.checked = g.rtcmBaseMessages.includes(inp.value);
        });
      }
    }
  }

  if (cfg.nmea) {
    const n = cfg.nmea;
    setVal("nmeaTalker", n.talker);
    setVal("nmeaRate", n.baseRateHz);
    if (Array.isArray(n.messages)) {
      const cont = document.getElementById("nmeaMessages");
      if (cont) {
        Array.from(cont.querySelectorAll("input[type=checkbox]")).forEach((inp) => {
          inp.checked = n.messages.includes(inp.value);
        });
      }
    }
  }

  if (cfg.imu) {
    const i = cfg.imu;
    const chk = document.getElementById("imuEnabled");
    if (chk && typeof i.enabled === "boolean") chk.checked = i.enabled;
    setVal("imuRate", i.rateHz);
    if (i.insFusion) {
      setVal("insPriority", i.insFusion.priority);
      setVal("insMaxGap", i.insFusion.maxGapNoGnssSec);
    }
  }

  logStatus("Configuración cargada en la UI.");
}

// ===== Exportar / importar JSON =====
function exportConfigJson() {
  const cfg = collectConfig();
  const json = JSON.stringify(cfg, null, 2);
  const preview = document.getElementById("configPreview");
  if (preview) preview.textContent = json;

  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "k922_com1_config.json";
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);

  logStatus("Configuración exportada como k922_com1_config.json.");
}

function importConfigJson(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const cfg = JSON.parse(e.target.result);
      applyConfigToUI(cfg);
      const preview = document.getElementById("configPreview");
      if (preview) preview.textContent = JSON.stringify(cfg, null, 2);
      logStatus("JSON importado correctamente.");
    } catch (err) {
      console.error(err);
      alert("No se pudo parsear el JSON.");
    }
  };
  reader.readAsText(file);
}

function sendApplyConfig() {
  const cfg = collectConfig();
  const msg = { type: "applyK922Config", payload: cfg };
  const json = JSON.stringify(msg);
  const preview = document.getElementById("configPreview");
  if (preview) preview.textContent = JSON.stringify(cfg, null, 2);
  logStatus("TX applyK922Config: " + JSON.stringify(cfg));

  if (!socket || socket.readyState !== WebSocket.OPEN) {
    logStatus("Backend no conectado. Solo se mostró la configuración.");
    alert("Backend no conectado. Primero pulsa CONECTAR.");
    return;
  }
  socket.send(json);
}

// ===== Bootstrap =====
document.addEventListener("DOMContentLoaded", () => {
  initTabs();
  initUI();
});
