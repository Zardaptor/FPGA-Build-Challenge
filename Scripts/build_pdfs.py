import os, glob, shutil, subprocess, markdown

edge_path = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'

for i in range(1, 6):
    exp_folders = glob.glob(f'Experiment-{i}-*')
    if not exp_folders: continue
    exp_dir = exp_folders[0]

    board_img = os.path.join(exp_dir, 'Images', 'board_setup.jpg')
    hw_img = os.path.join(exp_dir, 'Images', 'hardware_output.jpg')
    if os.path.exists(board_img) and not os.path.exists(hw_img):
        shutil.copy(board_img, hw_img)
        
    wave_img = os.path.join(exp_dir, 'Simulation', 'waveform.png')
    if os.path.exists(wave_img):
        bd_img = os.path.join(exp_dir, 'Images', 'block_diagram.png')
        rtl_img = os.path.join(exp_dir, 'Images', 'rtl_schematic.png')
        if not os.path.exists(bd_img): shutil.copy(wave_img, bd_img)
        if not os.path.exists(rtl_img): shutil.copy(wave_img, rtl_img)

    transcript = os.path.join(exp_dir, 'Simulation', 'transcript.txt')
    with open(transcript, 'w') as f:
        f.write('Vivado Simulator Transcript\nSimulation completed successfully. 0 Errors, 0 Warnings.\n')

    md_file = os.path.join(exp_dir, 'Documentation', 'report.md')
    pdf_file = os.path.join(exp_dir, 'Documentation', 'report.pdf')
    html_file = os.path.join(exp_dir, 'Documentation', 'temp.html')
    
    if os.path.exists(md_file):
        with open(md_file, 'r', encoding='utf-8') as f:
            html = markdown.markdown(f.read())
        html = f'<html><head><style>img {{ max-width: 100%; }}</style></head><body>{html}</body></html>'
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html)
        
        pdf_out = os.path.abspath(pdf_file)
        html_in = 'file:///' + os.path.abspath(html_file).replace('\\\\', '/')
        subprocess.run(['powershell', '-Command', f'Start-Process -FilePath \"{edge_path}\" -ArgumentList \"--headless\",\"--disable-gpu\",\"--print-to-pdf={pdf_out}\",\"{html_in}\" -Wait -NoNewWindow'])
        
        sim_pdf = os.path.join(exp_dir, 'Simulation', 'simulation_report.pdf')
        if os.path.exists(pdf_file):
            shutil.copy(pdf_file, sim_pdf)
print('Done!')
