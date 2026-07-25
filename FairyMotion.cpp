<!DOCTYPE html>
<html lang = "en">
<head>
<meta charset = "UTF-8">
<meta name = "viewport" content = "width=device-width, initial-scale=1.0, user-scalable=no">
<title>Fairy Koi Garden - Idle Mana Harvest< / title>
<style>
*{
    user - select: none;
    -webkit - tap - highlight - color: transparent;
}

body{
    margin : 0;
    padding : 0;
    background: linear - gradient(135deg, #1a472a 0 %, #2d5a3b 100 %);
    display: flex;
    justify - content: center;
    align - items: center;
    min - height: 100vh;
    font - family: 'Segoe UI', 'Quicksand', system - ui, -apple - system, sans - serif;
}

.game - container{
    background: #0a2f1f;
    border - radius: 40px;
    padding: 20px;
    box - shadow: 0 20px 40px rgba(0,0,0,0.4), inset 0 1px 2px rgba(255,255,255,0.1);
}

canvas{
    display: block;
    margin: 0 auto;
    border - radius: 24px;
    box - shadow: 0 8px 24px rgba(0,0,0,0.3);
    cursor: pointer;
}

.ui - panel{
    margin - top: 20px;
    display: flex;
    justify - content: space - between;
    align - items: center;
    gap: 15px;
    flex - wrap: wrap;
    background: rgba(30,20,15,0.7);
    backdrop - filter: blur(10px);
    padding: 12px 20px;
    border - radius: 60px;
}

.stat{
    background: rgba(0,0,0,0.6);
    padding: 8px 18px;
    border - radius: 40px;
    color: #ffefc0;
    font - weight: bold;
    display: flex;
    align - items: center;
    gap: 10px;
    font - size: 1.2rem;
}

.stat span : first - child{
    font - size: 1.4rem;
}

.stat.value{
    color: #ffd966;
    font - size: 1.4rem;
    font - weight: bold;
}

button{
    background: linear - gradient(135deg, #7c4d2a, #5a3a1a);
    border: none;
    color: #ffefb0;
    padding: 8px 20px;
    border - radius: 40px;
    font - weight: bold;
    font - size: 1rem;
    cursor: pointer;
    transition: transform 0.1s, box - shadow 0.1s;
    box - shadow: 0 4px 8px rgba(0,0,0,0.3);
}

button:active{
    transform: scale(0.96);
}

.upgrade{
    background: linear - gradient(135deg, #3c6e47, #2a5238);
}

@keyframes float{
    0 % { transform: translateY(0px); }
    100 % { transform: translateY(-5px); }
}

@media(max - width: 700px) {
    .stat{ font - size: 0.9rem; padding: 5px 12px; }
    .stat.value{ font - size: 1.1rem; }
    button{ padding: 6px 14px; font - size: 0.8rem; }
}
< / style>
< / head>
<body>
<div>
<div class = "game-container">
<canvas id = "gameCanvas" width = "900" height = "600">< / canvas>
<div class = "ui-panel">
<div class = "stat">
<span>✨< / span>
<span>Mana:< / span>
< span class = "value" id = "manaValue">0 < / span >
< / div>
<div class = "stat">
<span>🧚< / span>
<span>Fairies : < / span>
< span class = "value" id = "fairyCount">1 < / span >
< / div>
<div class = "stat">
<span>🌸< / span>
<span>Mana / sec : < / span>
< span class = "value" id = "manaPerSec">0 < / span >
< / div>
<button id = "buyFairyBtn" class = "upgrade">➕ Fairy(50🌿) < / button >
<button id = "upgradeSpeedBtn">⚡ Speed(30🌿) < / button >
< / div>
< / div>
<div style = "text-align: center; margin-top: 12px; color: #c8e6c0; font-size: 12px;">
🧚 Fairies harvest mana from glowing flowers 🐟 Koi swim gracefully
< / div>
< / div>

<script>
(function() {
    // Canvas setup
    const canvas = document.getElementById('gameCanvas');
    const ctx = canvas.getContext('2d');

    // Game dimensions
    const W = 900, H = 600;

    // ---------- GAME STATE ----------
    let mana = 150;  // start with some mana to buy upgrades
    let fairyCount = 1;
    let fairySpeedBase = 1.2;   // movement speed multiplier
    let autoHarvestInterval = null;

    // Fairies array
    let fairies = [];

    // Flowers array (static harvest points)
    let flowers = [];
    const FLOWER_COUNT = 6;

    // Koi fish
    let kois = [];
    const KOI_COUNT = 3;

    // Mouse interaction
    let mouseX = 0, mouseY = 0;
    let mousePressed = false;

    // Particles for effects
    let particles = [];

    // UI Elements
    const manaValueSpan = document.getElementById('manaValue');
    const fairyCountSpan = document.getElementById('fairyCount');
    const manaPerSecSpan = document.getElementById('manaPerSec');
    const buyFairyBtn = document.getElementById('buyFairyBtn');
    const upgradeSpeedBtn = document.getElementById('upgradeSpeedBtn');

    // ---------- Helper functions ----------
    function updateUI() {
        manaValueSpan.innerText = Math.floor(mana);
        fairyCountSpan.innerText = fairyCount;
        let totalHarvestRate = fairyCount * (0.8 + (fairySpeedBase * 0.2)); // each fairy harvests ~0.8-1.0 per sec based on speed
        let displayRate = (totalHarvestRate).toFixed(1);
        manaPerSecSpan.innerText = displayRate;
    }

    // Add mana with visual feedback
    function addMana(amount) {
        mana += amount;
        updateUI();
    }

    // Spawn floating particles (harvest effect)
    function addHarvestEffect(x, y) {
        for (let i = 0;i < 6;i++) {
            particles.push({
                x: x + (Math.random() - 0.5) * 20,
                y : y + (Math.random() - 0.5) * 20,
                vx : (Math.random() - 0.5) * 1.5,
                vy : Math.random() * -2 - 1,
                life : 1.0,
                size : 3 + Math.random() * 4,
                color : `hsl(${60 + Math.random() * 40}, 80 %, 65 %)`
            });
        }
    }

    // ---------- FAIRY CLASS ----------
    class Fairy {
        constructor(id, startX, startY) {
            this.id = id;
            this.x = startX || Math.random() * (W - 100) + 50;
            this.y = startY || Math.random() * (H - 150) + 50;
            this.targetFlower = null;
            this.harvestTimer = 0;
            this.speed = 0.9 + Math.random() * 0.5;
            this.angle = Math.random() * Math.PI * 2;
            this.wingPhase = 0;
            this.carryingGlow = 0;
            this.findNearestFlower();
        }

        findNearestFlower() {
            let closest = null;
            let minDist = Infinity;
            for (let f of flowers) {
                let dx = f.x - this.x;
                let dy = f.y - this.y;
                let dist = Math.hypot(dx, dy);
                if (dist < minDist && !f.isHarvesting) {
                    minDist = dist;
                    closest = f;
                }
            }
            if (closest) this.targetFlower = closest;
            else if (flowers.length > 0) this.targetFlower = flowers[0];
        }

        update(deltaTime) {
            if (!this.targetFlower || this.targetFlower.isHarvesting) {
                this.findNearestFlower();
            }

            if (this.targetFlower) {
                let dx = this.targetFlower.x - this.x;
                let dy = this.targetFlower.y - this.y;
                let dist = Math.hypot(dx, dy);

                if (dist < 18) {
                    // At flower: harvest
                    if (this.harvestTimer <= 0 && !this.targetFlower.isHarvesting) {
                        this.harvestFlower();
                    }
                    else {
                        this.harvestTimer -= deltaTime;
                        // hover while harvesting
                        this.wingPhase += deltaTime * 12;
                        this.carryingGlow = 0.8;
                    }
                }
                else {
                    // Move toward flower
                    let move = this.speed * fairySpeedBase * deltaTime * 180;
                    if (dist > move) {
                        let stepX = (dx / dist) * move;
                        let stepY = (dy / dist) * move;
                        this.x += stepX;
                        this.y += stepY;
                    }
                    else {
                        this.x = this.targetFlower.x;
                        this.y = this.targetFlower.y;
                    }
                    this.wingPhase += deltaTime * 15;
                    this.carryingGlow *= 0.96;
                }
            }
            else {
                // no flowers? wander
                this.angle += (Math.random() - 0.5) * deltaTime * 2;
                this.x += Math.cos(this.angle) * this.speed * deltaTime * 70;
                this.y += Math.sin(this.angle) * this.speed * deltaTime * 70;
                this.x = Math.min(W - 30, Math.max(30, this.x));
                this.y = Math.min(H - 70, Math.max(30, this.y));
                this.wingPhase += deltaTime * 12;
            }

            // boundary safety
            this.x = Math.min(W - 40, Math.max(40, this.x));
            this.y = Math.min(H - 80, Math.max(40, this.y));
        }

        harvestFlower() {
            if (!this.targetFlower || this.targetFlower.isHarvesting) return;
            this.targetFlower.isHarvesting = true;
            this.harvestTimer = 0.55; // harvest animation time

            // Give mana after short delay (simulate harvest)
            setTimeout(() = > {
                if (this.targetFlower && this.targetFlower.isHarvesting) {
                    let manaGain = 5 + Math.floor(Math.random() * 4);
                    addMana(manaGain);
                    addHarvestEffect(this.targetFlower.x, this.targetFlower.y);
                    this.targetFlower.isHarvesting = false;
                    this.targetFlower.resetTimer = 1.2; // flower cooldown visually
                    this.carryingGlow = 1.0;
                    // find new target after harvest
                    this.findNearestFlower();
                }
            }, 200);
        }

        draw(ctx) {
            // Glow if carrying mana
            let glowSize = 12 + 6 * this.carryingGlow;
            ctx.shadowBlur = 12;
            ctx.shadowColor = `rgba(255, 200, 100, ${ 0.4 + this.carryingGlow * 0.5 })`;
            // Body
                ctx.save();
            ctx.translate(this.x, this.y);
            let wingWobble = Math.sin(this.wingPhase) * 0.6;
            // Wings
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.quadraticCurveTo(-12 - wingWobble * 4, -12, -8, -4);
            ctx.quadraticCurveTo(-6 - wingWobble * 3, 0, 0, 0);
            ctx.fillStyle = `rgba(210, 230, 255, 0.85)`;
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.quadraticCurveTo(12 + wingWobble * 4, -12, 8, -4);
            ctx.quadraticCurveTo(6 + wingWobble * 3, 0, 0, 0);
            ctx.fill();
            // Body (fairy)
            ctx.beginPath();
            ctx.ellipse(0, 2, 6, 8, 0, 0, Math.PI * 2);
            ctx.fillStyle = "#ffe0b5";
            ctx.fill();
            ctx.fillStyle = "#f4c9a0";
            ctx.beginPath();
            ctx.ellipse(0, 0, 4, 5, 0, 0, Math.PI * 2);
            ctx.fill();
            // Glow sparkle
            if (this.carryingGlow > 0.2) {
                ctx.beginPath();
                ctx.arc(0, -2, 4 + 2 * Math.sin(Date.now() * 0.01), 0, Math.PI * 2);
                ctx.fillStyle = `rgba(255, 220, 100, ${ 0.4 * this.carryingGlow })`;
                ctx.fill();
            }
            ctx.restore();
            ctx.shadowBlur = 0;
        }
    }

    // ---------- FLOWER CLASS ----------
    class Flower {
        constructor(x, y) {
            this.x = x;
            this.y = y;
            this.isHarvesting = false;
            this.resetTimer = 0;
            this.pulse = 0;
        }

        update(deltaTime) {
            if (this.resetTimer > 0) {
                this.resetTimer -= deltaTime;
                if (this.resetTimer <= 0) this.isHarvesting = false;
            }
            this.pulse += deltaTime * 3;
        }

        draw(ctx) {
            let glow = 0.5 + Math.sin(this.pulse) * 0.3;
            if (this.isHarvesting) glow = 0.2;
            ctx.shadowBlur = 12;
            ctx.shadowColor = `rgba(255, 160, 80, ${ 0.5 + glow * 0.3 })`;
            // stem
                ctx.beginPath();
            ctx.moveTo(this.x, this.y);
            ctx.lineTo(this.x, this.y + 20);
            ctx.lineWidth = 4;
            ctx.strokeStyle = "#5f8b4c";
            ctx.stroke();
            // petals
            for (let i = 0;i < 5;i++) {
                let angle = (i / 5) * Math.PI * 2 + this.pulse;
                let xOff = Math.cos(angle) * 10;
                let yOff = Math.sin(angle) * 8;
                ctx.beginPath();
                ctx.ellipse(this.x + xOff, this.y + yOff, 6, 8, angle, 0, Math.PI * 2);
                ctx.fillStyle = `hsl(${ 40 + (this.isHarvesting ? 0 : 20) }, 80 %, ${ 65 + glow * 15 }%)`;
                ctx.fill();
            }
            // center
            ctx.beginPath();
            ctx.arc(this.x, this.y, 7, 0, Math.PI * 2);
            ctx.fillStyle = `#ffcc66`;
                ctx.fill();
            ctx.beginPath();
            ctx.arc(this.x, this.y, 4, 0, Math.PI * 2);
            ctx.fillStyle = `#ffaa44`;
                ctx.fill();
            ctx.shadowBlur = 0;
        }
    }

    // ---------- KOI FISH ----------
    class Koi {
        constructor() {
            this.reset();
        }
        reset() {
            this.x = Math.random() * W;
            this.y = H - 60 - Math.random() * 120;
            this.vx = (Math.random() - 0.5) * 25;
            this.vy = (Math.random() - 0.5) * 12;
            this.tail = 0;
        }
        update(deltaTime) {
            this.x += this.vx * deltaTime;
            this.y += this.vy * deltaTime;
            if (this.x < -50) this.x = W + 30;
            if (this.x > W + 50) this.x = -30;
            if (this.y < H - 180) this.y = H - 180;
            if (this.y > H - 20) this.y = H - 20;
            this.tail += deltaTime * 12;
        }
        draw(ctx) {
            ctx.save();
            ctx.translate(this.x, this.y);
            let angle = Math.atan2(this.vy, this.vx);
            ctx.rotate(angle);
            ctx.fillStyle = "#e6733e";
            ctx.beginPath();
            ctx.ellipse(0, 0, 20, 10, 0, 0, Math.PI * 2);
            ctx.fill();
            ctx.fillStyle = "#ff9966";
            ctx.beginPath();
            ctx.ellipse(4, -2, 5, 4, 0, 0, Math.PI * 2);
            ctx.fill();
            // tail
            let tailWag = Math.sin(this.tail) * 0.6;
            ctx.beginPath();
            ctx.moveTo(-18, -5);
            ctx.quadraticCurveTo(-26 + tailWag * 4, 0, -18, 5);
            ctx.fill();
            ctx.fillStyle = "#cc5533";
            ctx.fill();
            ctx.fillStyle = "#000";
            ctx.beginPath();
            ctx.arc(10, -3, 2, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        }
    }

    // ---------- PARTICLE SYSTEM ----------
    function updateParticles(deltaTime) {
        for (let i = 0;i < particles.length;i++) {
            let p = particles[i];
            p.x += p.vx;
            p.y += p.vy;
            p.life -= deltaTime * 1.5;
            if (p.life <= 0 || p.y < -20) {
                particles.splice(i, 1);
                i--;
            }
        }
    }

    function drawParticles(ctx) {
        for (let p of particles) {
            ctx.globalAlpha = p.life * 0.8;
            ctx.fillStyle = p.color;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size * p.life, 0, Math.PI * 2);
            ctx.fill();
        }
        ctx.globalAlpha = 1;
    }

    // ---------- GAME LOOP ----------
    let lastTimestamp = 0;
    let deltaTime = 1 / 60;

    function gameLoop(now) {
        requestAnimationFrame(gameLoop);
        if (!lastTimestamp) { lastTimestamp = now; return; }
        deltaTime = Math.min(0.033, (now - lastTimestamp) / 1000);
        if (deltaTime <= 0) { lastTimestamp = now; return; }
        lastTimestamp = now;

        // Update fairies
        for (let f of fairies) f.update(deltaTime);
        // Update flowers
        for (let f of flowers) f.update(deltaTime);
        // Update Koi
        for (let k of kois) k.update(deltaTime);
        // Update particles
        updateParticles(deltaTime);

        // Idle passive income (just in case fairies are stuck)
        // but fairies handle harvest, nothing else needed

        draw();
        updateUI();
    }

    function draw() {
        ctx.clearRect(0, 0, W, H);
        // Water ripple background
        let grad = ctx.createLinearGradient(0, 0, 0, H);
        grad.addColorStop(0, '#2c6e3c');
        grad.addColorStop(0.6, '#1d5930');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, W, H);

        // Draw pond bottom
        ctx.fillStyle = "#3b8f5e";
        ctx.fillRect(0, H - 90, W, 90);
        for (let i = 0;i < 80;i++) {
            ctx.fillStyle = `rgba(100, 180, 100, 0.2)`;
            ctx.beginPath();
            ctx.ellipse((i * 37) % W, H - 75 + Math.sin(Date.now() * 0.002 + i) * 5, 15, 5, 0, 0, Math.PI * 2);
            ctx.fill();
        }

        // Draw flowers
        for (let f of flowers) f.draw(ctx);
        // Draw Koi
        for (let k of kois) k.draw(ctx);
        // Draw Fairies
        for (let f of fairies) f.draw(ctx);
        // Particles on top
        drawParticles(ctx);

        // Mouse interactive sparkle
        if (mousePressed) {
            ctx.beginPath();
            ctx.arc(mouseX, mouseY, 12, 0, Math.PI * 2);
            ctx.fillStyle = "rgba(255,230,150,0.3)";
            ctx.fill();
        }
    }

    // ---------- ADD/REMOVE FAIRIES ----------
    function addFairy() {
        fairyCount++;
        fairies.push(new Fairy(fairies.length, W / 2 + (Math.random() - 0.5) * 150, H / 2 + (Math.random() - 0.5) * 100));
        updateUI();
    }

    function buyFairy() {
        let cost = 50;
        if (mana >= cost) {
            addMana(-cost);
            addFairy();
        }
        else {
            // flash feedback
            canvas.style.filter = "brightness(0.9)";
            setTimeout(() = > canvas.style.filter = "", 150);
        }
    }

    function upgradeSpeed() {
        let cost = 30;
        if (mana >= cost) {
            addMana(-cost);
            fairySpeedBase += 0.22;
            updateUI();
            // add particle celebration
            for (let i = 0;i < 12;i++) particles.push({
                x: W / 2, y : H - 50, vx : (Math.random() - 0.5) * 4, vy : -Math.random() * 4,
                life : 0.8, size : 4, color : "#ffffaa"
                });
        }
        else {
            canvas.style.filter = "brightness(0.9)";
            setTimeout(() = > canvas.style.filter = "", 150);
        }
    }

    // ----- Initialize world -----
    function initFlowers() {
        let positions = [
            [150, 420], [300, 480], [500, 390], [680, 450], [780, 380], [420, 530]
        ];
        for (let i = 0;i < FLOWER_COUNT;i++) {
            let pos = positions[i % positions.length];
            flowers.push(new Flower(pos[0], pos[1]));
        }
    }

    function initKois() {
        for (let i = 0;i < KOI_COUNT;i++) kois.push(new Koi());
    }

    function initFairies() {
        fairies = [];
        for (let i = 0;i < fairyCount;i++) {
            fairies.push(new Fairy(i, 100 + i * 80, 250));
        }
    }

    // Event listeners
    canvas.addEventListener('mousemove', (e) = > {
        let rect = canvas.getBoundingClientRect();
        let scaleX = canvas.width / rect.width;
        let scaleY = canvas.height / rect.height;
        mouseX = (e.clientX - rect.left) * scaleX;
        mouseY = (e.clientY - rect.top) * scaleY;
    });
    canvas.addEventListener('mousedown', () = > { mousePressed = true; });
    window.addEventListener('mouseup', () = > { mousePressed = false; });
    canvas.addEventListener('touchmove', (e) = > {
        e.preventDefault();
        let rect = canvas.getBoundingClientRect();
        let touch = e.touches[0];
        let scaleX = canvas.width / rect.width;
        let scaleY = canvas.height / rect.height;
        mouseX = (touch.clientX - rect.left) * scaleX;
        mouseY = (touch.clientY - rect.top) * scaleY;
        mousePressed = true;
    });
    canvas.addEventListener('touchend', () = > { mousePressed = false; });

    buyFairyBtn.addEventListener('click', buyFairy);
    upgradeSpeedBtn.addEventListener('click', upgradeSpeed);

    // start game
    initFlowers();
    initKois();
    initFairies();
    updateUI();

    // Background idle auto-save not needed but small extra loop for mana regen passive
    setInterval(() = > {
        // just to ensure UI updates when idle harvest triggers from fairies
        updateUI();
    }, 200);

    requestAnimationFrame(gameLoop);
})();
< / script>
< / body>
< / html>