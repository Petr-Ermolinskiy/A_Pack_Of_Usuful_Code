import logging
from pathlib import Path

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
        df = self.process_all_files()
        return df
    
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