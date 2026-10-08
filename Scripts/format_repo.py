import os
import shutil

base_dir = r"c:\Users\suraj\Desktop\Projects\FPGA\FPGA-Build-Challenge-Suraj"

experiments = [
    "Experiment-1-Beginner",
    "Experiment-2-Beginner",
    "Experiment-3-Intermediate",
    "Experiment-4-Intermediate",
    "Experiment-5-Advanced"
]

for exp in experiments:
    exp_path = os.path.join(base_dir, exp)
    if not os.path.exists(exp_path):
        continue
        
    # Create required folders
    for folder in ["Documentation", "Simulation", "Images"]:
        os.makedirs(os.path.join(exp_path, folder), exist_ok=True)
        
    # Create Video_Link.txt
    with open(os.path.join(exp_path, "Video_Link.txt"), "w") as f:
        f.write("Google Drive Link: [INSERT LINK HERE]\n")
        
    # Move constraints to RTL to match rubric
    old_const_dir = os.path.join(exp_path, "Constraints")
    rtl_dir = os.path.join(exp_path, "RTL")
    os.makedirs(rtl_dir, exist_ok=True)
    
    if os.path.exists(old_const_dir):
        for file in os.listdir(old_const_dir):
            if file.endswith(".xdc"):
                src = os.path.join(old_const_dir, file)
                dst = os.path.join(rtl_dir, file)
                shutil.move(src, dst)
        # Remove old constraints dir if empty
        try:
            os.rmdir(old_const_dir)
        except OSError:
            pass

# Create Final Report folder
os.makedirs(os.path.join(base_dir, "Final_Report"), exist_ok=True)

print("Repository structure formatted perfectly according to V-SPACE guidelines!")
