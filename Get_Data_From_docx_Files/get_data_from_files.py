import logging
from pathlib import Path
import shutil

import pandas as pd
from docx import Document


logging.basicConfig(level=logging.INFO)

class GetDataFromFiles:
    def __init__(self, main_path: str, *args, **kwargs):
        self.main_path = main_path
        
        # шаблон датасета, куда будет всё сохраняться
        self.df_template = pd.DataFrame(columns=["Дата", 
                                                 "Год",
                                                 "Папка",
                                                 "Название файла", 
                                                 "Исполнитель(и)", 
                                                 "Название эксперимента"])
        # все пути до docx файлов
        self.docx_files = self.get_files_paths()
    
    def get_files_paths(self)->list:
        """ 
        Возвращает все полные пути до всех файлов docx
        """
        def get_docx_files(root_dir):
            root_path = Path(root_dir)
            return [file.as_posix() for file in root_path.rglob('*.docx') if ".venv" not in file.as_posix()]

        return get_docx_files(self.main_path)
    
    def run(self):
        # перемещаем все файлы из подпапок в папке имени (если они есть) в одну папку
        self.move_files_from_subfolders()
        # читаем все файлы
        df = self.process_all_files()
        return df
    
    def move_files_from_subfolders(self)->None:
        """ Перемещаем все файлы из возможных подпапок в папках год/фио в одну папку """
        base_dir = Path(self.main_path)
        
        for fio_folder in base_dir.glob("*/*"):  # ищет папки в папках год/фио
            if fio_folder.is_dir():
                for docx_file in fio_folder.rglob("*.docx"):
                    # Ensure it's inside a subfolder (not directly in fio_folder)
                    if docx_file.parent != fio_folder:
                        # Move file to the fio_folder
                        target_path = fio_folder / docx_file.name
                        logging.info(f"Перемещаем файл {docx_file} -> {target_path}")
                        shutil.move(str(docx_file), str(target_path))
                        
        # обновляем пути до файлов
        self.docx_files = self.get_files_paths()
        return None
        
    
    def process_all_files(self)->pd.DataFrame:
        """ В каждом файле выделяем нужную информацию. Часть информации берем из пути к файлу """
        df_main_data = self.df_template.copy()
        
        for i, path in enumerate(self.docx_files):
            year, fio, title = path.split("/")[-3:]
            date = GetDataFromFiles.get_date_from_title(title)
            try:
                names_of_workers, experiment_info = GetDataFromFiles.process_one_file(path)
            except Exception as e:
                logging.warning(f"Файл {path}::{e}")
                continue
            
            if not experiment_info and not names_of_workers:
                continue
            # добавляем информацию в датафрейм
            df_main_data.loc[i] = date, year, fio, title, names_of_workers, experiment_info
        return df_main_data
    
    @staticmethod
    def process_one_file(file_path)->tuple:
        document = Document(file_path)

        experiment_info = None
        names_of_workers = None
        
        # находим цели и исполнителей
        flag_name = False
        for i, p in enumerate(document.paragraphs):
            if "Наименование эксперимент" in p.text:
                flag_name = True
                continue
            if flag_name:
                experiment_info = p.text
                flag_name = False
            
            if "Исполнители (ФИО):" in p.text:
                names_of_workers = p.text.replace("Исполнители (ФИО):", "").replace(".", "").strip()
                break # больше нечего смотреть
        return names_of_workers, experiment_info
    
    @staticmethod
    def get_date_from_title(path: str)->str:
        return "-".join(path.split("-")[0:3])