import psycopg2
from psycopg2 import sql
import os

# --- Configurações de Conexão com o Banco de Dados ---
# Substitua com suas credenciais do PostgreSQL
DB_CONFIG = {
    "dbname": "db_agricultura_sc",
    "user": "postgres",
    "password": "123456",
    "host": "localhost",
    "port": "5432"
}

def connect():
    """ Conecta ao servidor PostgreSQL e retorna o objeto de conexão. """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.OperationalError as e:
        print(f"Erro ao conectar ao banco de dados: {e}")
        return None

def clear_screen():
    """ Limpa a tela do console. """
    os.system('cls' if os.name == 'nt' else 'clear')

def list_rural_properties():
    """ Lista todos os imóveis rurais para ajudar o usuário. """
    conn = connect()
    if conn is None:
        return

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id_imovel_rural, nome_imovel FROM IMOVEL_RURAL ORDER BY nome_imovel;")
            properties = cur.fetchall()
            if not properties:
                print("Nenhum imóvel rural cadastrado.")
                return
            
            print("\n--- Imóveis Rurais Disponíveis ---")
            for prop in properties:
                print(f"ID: {prop[0]:<5} | Nome: {prop[1]}")
            print("---------------------------------")
            
    except psycopg2.Error as e:
        print(f"Erro ao buscar imóveis: {e}")
    finally:
        if conn:
            conn.close()


def register_agricultural_production():
    """
    Funcionalidade 1: Cadastra uma nova produção agrícola associada a um imóvel rural.
    Envolve as tabelas: PRODUCAO_AGRICOLA e IMOVEL_RURAL.
    """
    clear_screen()
    print("--- Cadastro de Nova Produção Agrícola ---")
    
    # Mostra os imóveis disponíveis para o usuário escolher
    list_rural_properties()
    
    try:
        id_imovel = int(input("Digite o ID do Imóvel Rural: "))
        cultura = input("Digite o nome da cultura plantada (ex: Soja, Milho): ")
        area_ha = float(input("Digite a área cultivada em hectares (ex: 50.5): "))
        data_plantio = input("Digite a data de plantio (formato AAAA-MM-DD): ")
        safra = input("Digite a safra (ex: 2023/2024): ")
        status = 'Planejada' # Começa como 'Planejada' por padrão
    except ValueError:
        print("\nErro: Entrada inválida. Verifique os valores e tente novamente.")
        return

    conn = connect()
    if conn is None:
        return

    try:
        with conn.cursor() as cur:
            # SQL para inserir a nova produção
            insert_query = """
            INSERT INTO PRODUCAO_AGRICOLA 
            (id_imovel_rural, cultura_plantada, area_cultivada_ha, data_plantio, safra, status_producao)
            VALUES (%s, %s, %s, %s, %s, %s);
            """
            cur.execute(insert_query, (id_imovel, cultura, area_ha, data_plantio, safra, status))
            conn.commit()
            print(f"\nSucesso! Produção de '{cultura}' cadastrada no imóvel ID {id_imovel}.")
            
    except psycopg2.Error as e:
        print(f"\nErro ao inserir no banco de dados: {e}")
        conn.rollback() # Desfaz a transação em caso de erro
    finally:
        if conn:
            conn.close()

def generate_owners_report():
    """
    Funcionalidade 2: Gera um relatório listando imóveis e seus respectivos proprietários.
    Envolve as tabelas: IMOVEL_RURAL, PROPRIEDADE, PESSOA, PESSOA_FISICA, PESSOA_JURIDICA.
    """
    clear_screen()
    print("--- Relatório de Imóveis e Proprietários ---")
    
    conn = connect()
    if conn is None:
        return
        
    try:
        with conn.cursor() as cur:
            report_query = """
            SELECT
                ir.nome_imovel,
                ir.area_total_ha,
                COALESCE(pf.nome_completo, pj.razao_social) AS proprietario,
                p.tipo_pessoa,
                pr.percentual_propriedade
            FROM IMOVEL_RURAL ir
            JOIN PROPRIEDADE pr ON ir.id_imovel_rural = pr.id_imovel_rural
            JOIN PESSOA p ON pr.id_pessoa = p.id_pessoa
            LEFT JOIN PESSOA_FISICA pf ON p.id_pessoa = pf.id_pessoa AND p.tipo_pessoa = 'F'
            LEFT JOIN PESSOA_JURIDICA pj ON p.id_pessoa = pj.id_pessoa AND p.tipo_pessoa = 'J'
            ORDER BY ir.nome_imovel, proprietario;
            """
            cur.execute(report_query)
            report_data = cur.fetchall()
            
            if not report_data:
                print("Nenhum dado encontrado para o relatório.")
                return
            
            # Imprime o cabeçalho do relatório
            print(f"{'Imóvel Rural':<30} | {'Área (ha)':<10} | {'Proprietário':<40} | {'Tipo':<5} | {'Posse (%)':<10}")
            print("-" * 110)
            
            # Imprime os dados
            for row in report_data:
                nome_imovel, area, proprietario, tipo, percentual = row
                tipo_str = 'Física' if tipo == 'F' else 'Jurídica'
                print(f"{nome_imovel:<30} | {area:<10.2f} | {proprietario:<40} | {tipo_str:<5} | {percentual:<10.2f}")
                
    except psycopg2.Error as e:
        print(f"Erro ao gerar o relatório: {e}")
    finally:
        if conn:
            conn.close()

def main_menu():
    """ Exibe o menu principal e gerencia a navegação do usuário. """
    while True:
        clear_screen()
        print("===== Portal da Agricultura e Meio Ambiente =====")
        print("1. Cadastrar nova Produção Agrícola")
        print("2. Gerar Relatório de Proprietários")
        print("0. Sair")
        print("================================================")
        
        choice = input("Escolha uma opção: ")
        
        if choice == '1':
            register_agricultural_production()
        elif choice == '2':
            generate_owners_report()
        elif choice == '0':
            print("Saindo do sistema. Até logo!")
            break
        else:
            print("Opção inválida, tente novamente.")
            
        input("\nPressione Enter para continuar...")


if __name__ == "__main__":
    main_menu()