#!/bin/bash
# Start all presentation services

echo "🚀 Starting Darwin Presentation Services..."
echo ""

# 0. Landing page (port 8700)
echo "Starting landing page (port 8700)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds/presentation/landing
python3 -m http.server 8700 > /tmp/landing.log 2>&1 &
echo "  PID: $!"

# 1. Main site (port 9000)
echo "Starting main site (port 9000)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds/presentation/site
python3 -m http.server 9000 > /tmp/site.log 2>&1 &
echo "  PID: $!"

# 1b. Files site (port 8800)
echo "Starting files site (port 8800)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds/presentation/files
python3 -m http.server 8800 > /tmp/files.log 2>&1 &
echo "  PID: $!"

# 2. Slides (port 8100)
echo "Starting slides (port 8100)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds/presentation/slides
python3 -m http.server 8100 > /tmp/slides.log 2>&1 &
echo "  PID: $!"

# 3. Dashboard 1 (port 8501)
echo "Starting Dashboard 1 - Ultra Epic (port 8501)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds
streamlit run apps/streamlit_advanced/ultra_epic_dashboard.py --server.port 8501 --server.headless true > /tmp/dashboard1.log 2>&1 &
echo "  PID: $!"

# 4. Dashboard 2 (port 8502)
echo "Starting Dashboard 2 - 3D Analysis (port 8502)..."
streamlit run apps/streamlit_advanced/dashboard_with_3d_analysis.py --server.port 8502 --server.headless true > /tmp/dashboard2.log 2>&1 &
echo "  PID: $!"

# 5. Dashboard 3 (port 8503)
echo "Starting Dashboard 3 - Statistical (port 8503)..."
streamlit run apps/streamlit_advanced/epic_dashboard_n2480.py --server.port 8503 --server.headless true > /tmp/dashboard3.log 2>&1 &
echo "  PID: $!"

# 6. Darwin Scaffold Studio (port 8600)
echo "Starting Darwin Scaffold Studio (port 8600)..."
cd /home/agourakis82/workspace/kec-biomaterials-scaffolds
streamlit run apps/production/darwin_scaffold_studio.py --server.port 8600 --server.headless true > /tmp/scaffold_studio.log 2>&1 &
echo "  PID: $!"

echo ""
echo "⏳ Waiting for services to start..."
sleep 12

echo ""
echo "✅ All services started!"
echo ""
echo "Local URLs:"
echo "  Landing Page: http://localhost:8700"
echo "  Main Site:    http://localhost:9000"
echo "  Files:        http://localhost:8800"
echo "  Slides:       http://localhost:8100"
echo "  Dashboard 1:  http://localhost:8501"
echo "  Dashboard 2:  http://localhost:8502"
echo "  Dashboard 3:  http://localhost:8503"
echo "  Scaffold Studio: http://localhost:8600"
echo ""
echo "Public URLs (via tunnel):"
echo "  🏠 Landing: https://studio.agourakis.med.br"
echo "  🏭 Studio App: https://studio.agourakis.med.br/app"
echo "  📄 Files: https://files.agourakis.med.br"
echo "  📖 Main Site: https://project.agourakis.med.br"
echo "  🎬 Slides: https://slides.agourakis.med.br"
echo "  📊 Dashboards: https://dashboard1/2/3.agourakis.med.br"
echo ""
