import os

def get_path_list(_folder ):
    folder_path = _folder
    assert os.path.exists(folder_path)
    assert os.path.isdir(folder_path)
    # return all file names including folder names
    return os.listdir(folder_path)