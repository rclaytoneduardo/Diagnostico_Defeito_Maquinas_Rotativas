<h2 align="center"> Aplicação de Aprendizado de Máquina para Classificação de Defeitos em Máquinas Rotativas Usando Espectros </h2>

<h4 align="justify">  Os códigos-fonte diponibilizados aqui foram desenvolvidos em um trabalho de pesquisa de análise comparativa do desempenho de diferentes técnicas de aprendizado de máquina para a classificação de defeitos em máquinas rotativas, usando imagens para extração automática das características. Os classificadores propostos neste trabalho foram treinados com dados simulados e testados tanto com dados simulados quanto experimentais. Os dados experimentais foram obtidos através de um sistema rotativo experimental de laboratório. Para geração dos dados simulados, foi desenvolvido um modelo de elementos finitos do sistema rotativo experimental. Dados de vibração do sistema rotativo na presença de diferentes tipos de defeitos: desbalanceamento, desalinhamento, trinca transversal no eixo, roçamento do rotor e instabilidade hidrodinâmica, foram usados para avaliação do desempenho de vários métodos de classificação. Foram avaliados os seguintes métodos de classificação: análise discriminante quadrática, árvore de decisão, rede neural convolucional, k-vizinhos mais próximos, quantização vetorial por aprendizagem, naive Bayes, autocodificador empilhado e máquinas de vetores de suporte. Eles foram combinados com métodos de redução de dimensionalidade e métodos baseados em sistemas de múltiplos classificadores ou ensembles. </h4>

## Como usar os códigos-fonte

### Pré-requisitos
Será necessário usar os seguintes softwares:
 - Matlab versão 2018b ou superior;
 - LabVIEW versão 2014 ou superior.
 
 ### Organização
 
 Os códigos-fonte foram organizados da seguinte forma:
 - <h4> Classificadores </h4>: Neste local foram armazenados os padrões (imagens) para treinamento e teste, obtidos via simulação computacional e ensaios experimentais, e os diferentes métodos de classificação analisados nesse trabalho de pesquisa.  
 - Ensaio_Experimental: Algoritmos para geração dos padrões a partir dos dados obtidos via sistema de aquisição de dados em LabView; 
 - Simulacao_Computacional: Algoritmos para geração dos padrões a partir dos dados obtidos via simulação computacional;
 - Sistema_Aquisicao_Dados: Sistema de aquisição de dados desenvolvido em LabView para coleta dos sinais de vibração e do tacômetro.
 
 ### Rodando a simulação computacional
 
 Para a simulação computacional do sistema rotodinâmico e geraçao dos padrões de treinamento e teste, basta executar os códigos com prefixo "rotorsystem". Por exemplo, o código "rotorsystem_Cra_n7_9_11_13_15.m" gera os padrões para trinca transversal com o disco nas posições dos nós 7, 9, 11, 13 e 15. 
 
 ### Licença
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
