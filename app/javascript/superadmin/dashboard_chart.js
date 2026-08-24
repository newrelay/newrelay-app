// Smooth Canvas Spline Chart for Super Admin Conversation Activity

export function initActivityChart(chartData = []) {
  const chartCanvas = document.getElementById('activityChartCanvas');
  if (!chartCanvas) return;

  const chartCtx = chartCanvas.getContext('2d');
  const tooltip = document.getElementById('chartTooltip');
  const tooltipDate = document.getElementById('tooltipDate');
  const tooltipCount = document.getElementById('tooltipCount');

  // Fallback dataset if empty
  const data = chartData.length > 0 ? chartData : [
    { date: '2026-07-20', val: 0 }, { date: '2026-07-21', val: 0 }, { date: '2026-07-22', val: 0 },
    { date: '2026-07-23', val: 0 }, { date: '2026-07-24', val: 0 }, { date: '2026-07-25', val: 0 },
    { date: '2026-07-26', val: 0 }, { date: '2026-07-27', val: 0 }, { date: '2026-07-28', val: 0 },
    { date: '2026-07-29', val: 0 }, { date: '2026-07-30', val: 0 }, { date: '2026-07-31', val: 96 },
    { date: '2026-08-01', val: 0 }, { date: '2026-08-02', val: 0 }, { date: '2026-08-03', val: 0 },
    { date: '2026-08-04', val: 0 }, { date: '2026-08-05', val: 0 }, { date: '2026-08-06', val: 0 }
  ];

  function drawChart(activeX = null, activeY = null) {
    const dpr = window.devicePixelRatio || 1;
    const container = chartCanvas.parentElement;
    if (!container) return;
    const rect = container.getBoundingClientRect();
    const width = Math.max(300, rect.width - 32);
    const height = 340;

    chartCanvas.width = width * dpr;
    chartCanvas.height = height * dpr;
    chartCanvas.style.width = `${width}px`;
    chartCanvas.style.height = `${height}px`;

    chartCtx.save();
    chartCtx.scale(dpr, dpr);

    const isDark = document.documentElement.classList.contains('dark');
    const primaryColor = isDark ? '#7373f7' : '#5b5bd6';
    const gridColor = isDark ? 'rgba(255, 255, 255, 0.06)' : '#f1f5f9';
    const textColor = '#94a3b8';

    const paddingLeft = 45;
    const paddingRight = 20;
    const paddingTop = 20;
    const paddingBottom = 70;

    const chartW = width - paddingLeft - paddingRight;
    const chartH = height - paddingTop - paddingBottom;

    chartCtx.clearRect(0, 0, width, height);

    const maxVal = Math.max(96, ...data.map(d => d.val));
    const ySteps = 16;
    chartCtx.font = '10.5px Inter, sans-serif';
    chartCtx.fillStyle = textColor;
    chartCtx.textAlign = 'right';

    for (let i = 0; i <= ySteps; i++) {
      const val = Math.round((i / ySteps) * maxVal);
      const y = paddingTop + (1 - val / maxVal) * chartH;

      chartCtx.beginPath();
      chartCtx.strokeStyle = gridColor;
      chartCtx.lineWidth = 1;
      chartCtx.moveTo(paddingLeft, y);
      chartCtx.lineTo(width - paddingRight, y);
      chartCtx.stroke();

      chartCtx.fillText(val.toString(), paddingLeft - 8, y + 3.5);
    }

    const points = data.map((d, i) => {
      const x = paddingLeft + (i / (data.length - 1)) * chartW;
      const y = paddingTop + (1 - d.val / maxVal) * chartH;
      return { x, y, ...d };
    });

    // Area fill
    const gradient = chartCtx.createLinearGradient(0, paddingTop, 0, height - paddingBottom);
    gradient.addColorStop(0, isDark ? 'rgba(115, 115, 247, 0.35)' : 'rgba(91, 91, 214, 0.22)');
    gradient.addColorStop(1, isDark ? 'rgba(115, 115, 247, 0)' : 'rgba(91, 91, 214, 0)');

    chartCtx.beginPath();
    chartCtx.moveTo(points[0].x, height - paddingBottom);
    chartCtx.lineTo(points[0].x, points[0].y);

    for (let i = 0; i < points.length - 1; i++) {
      const curr = points[i];
      const next = points[i + 1];
      const cx = (curr.x + next.x) / 2;
      chartCtx.bezierCurveTo(cx, curr.y, cx, next.y, next.x, next.y);
    }

    chartCtx.lineTo(points[points.length - 1].x, height - paddingBottom);
    chartCtx.closePath();
    chartCtx.fillStyle = gradient;
    chartCtx.fill();

    // Spline line
    chartCtx.beginPath();
    chartCtx.moveTo(points[0].x, points[0].y);
    for (let i = 0; i < points.length - 1; i++) {
      const curr = points[i];
      const next = points[i + 1];
      const cx = (curr.x + next.x) / 2;
      chartCtx.bezierCurveTo(cx, curr.y, cx, next.y, next.x, next.y);
    }
    chartCtx.strokeStyle = primaryColor;
    chartCtx.lineWidth = 2.2;
    chartCtx.stroke();

    // Peak dot
    const peakIndex = points.reduce((maxI, p, i, arr) => (p.val > arr[maxI].val ? i : maxI), 0);
    const peakPoint = points[peakIndex];
    if (peakPoint && peakPoint.val > 0) {
      chartCtx.beginPath();
      chartCtx.arc(peakPoint.x, peakPoint.y, 4.5, 0, Math.PI * 2);
      chartCtx.fillStyle = primaryColor;
      chartCtx.fill();
      chartCtx.strokeStyle = isDark ? '#181d27' : '#ffffff';
      chartCtx.lineWidth = 2;
      chartCtx.stroke();
    }

    if (activeX !== null && activeY !== null) {
      chartCtx.beginPath();
      chartCtx.arc(activeX, activeY, 5.5, 0, Math.PI * 2);
      chartCtx.fillStyle = primaryColor;
      chartCtx.fill();
      chartCtx.strokeStyle = isDark ? '#181d27' : '#ffffff';
      chartCtx.lineWidth = 2;
      chartCtx.stroke();
    }

    chartCtx.restore();
  }

  window.addEventListener('resize', drawChart);
  window.addEventListener('nr-theme-changed', drawChart);
  drawChart();

  chartCanvas.addEventListener('mousemove', (e) => {
    const rect = chartCanvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const paddingLeft = 45;
    const paddingRight = 20;
    const chartW = rect.width - paddingLeft - paddingRight;

    if (x < paddingLeft || x > rect.width - paddingRight) {
      if (tooltip) tooltip.style.display = 'none';
      drawChart();
      return;
    }

    const step = chartW / (data.length - 1);
    const index = Math.round((x - paddingLeft) / step);
    const clampedIndex = Math.max(0, Math.min(data.length - 1, index));
    const item = data[clampedIndex];

    const pointX = paddingLeft + clampedIndex * step;
    const maxVal = Math.max(96, ...data.map(d => d.val));
    const paddingTop = 20;
    const paddingBottom = 70;
    const chartH = 340 - paddingTop - paddingBottom;
    const pointY = paddingTop + (1 - item.val / maxVal) * chartH;

    drawChart(pointX, pointY);

    if (tooltip && tooltipDate && tooltipCount) {
      tooltip.style.display = 'block';
      tooltip.style.left = `${pointX}px`;
      tooltip.style.top = `${pointY}px`;
      tooltipDate.textContent = item.date;
      tooltipCount.innerHTML = `<span class="chart-tooltip-swatch"></span>Conversations: ${item.val}`;
    }
  });

  chartCanvas.addEventListener('mouseleave', () => {
    if (tooltip) tooltip.style.display = 'none';
    drawChart();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initActivityChart();
});
