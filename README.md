<h2 align="center">  Software da Dissertação "Aplicação de Aprendizado de Máquina para Classificação de Defeitos em Máquinas Rotativas Usando Espectros das Órbitas" </h2>

**Autor:** Clayton E. Rodrigues (rclaytoneduardo@gmail.com), ITA  
**Orientadores:** Cairo L. Nascimento Jr. (cairo@ita.br), Domingos A. Rade (rade@ita.br), ITA.

Dissertação e outras publicações de Clayton E. Rodrigues disponíveis em [ftp://labattmot.ele.ita.br/ele/clayton/My_Publications/](ftp://labattmot.ele.ita.br/ele/clayton/My_Publications/)

### Resumo:

Os códigos disponibilizados foram desenvolvidos em um trabalho de pesquisa de análise comparativa do desempenho de diferentes técnicas de aprendizado de máquina para a classificação de defeitos em máquinas rotativas, usando imagens para extração automática das características.

Os classificadores propostos neste trabalho foram treinados com dados simulados e testados tanto com dados simulados quanto experimentais.

Os dados experimentais foram obtidos através de um sistema rotativo experimental de laboratório. Para geração dos dados simulados, foi desenvolvido um modelo de elementos finitos do sistema rotativo experimental.

Dados de vibração do sistema rotativo na presença de diferentes tipos de defeitos (desbalanceamento, desalinhamento, trinca transversal no eixo, roçamento do rotor e instabilidade hidrodinâmica) foram usados para avaliação do desempenho de vários métodos de classificação.

Foram avaliados os seguintes métodos de classificação: análise discriminante quadrática, árvore de decisão, rede neural convolucional, k-vizinhos mais próximos, quantização vetorial por aprendizagem, naive Bayes, autocodificadores empilhados e máquinas de vetores de suporte.

Esses métodos de classificação foram combinados com métodos de redução de dimensionalidade e métodos baseados em sistemas de múltiplos classificadores ou ensembles.

### Pré-requisitos para execução dos meus programas:

Os seguintes softwares devem ser instalados para execução dos meus programas:

*   Matlab versão 2018b ou superior;
*   LabVIEW versão 2014 ou superior.

Para execução dos meus programas, foi utilizado um notebook da marca Dell, modelo Inspiron, processador Intel Core i7-6500U de 2,50 GHz, 16 GB de memória RAM, 1 TB de HD e sistema operacional Window 10.

### Organização do código-fonte:

O código-fonte aqui disponibilizado possui a seguinte estrutura de diretórios:

<pre>- Codigos_LabView
  |- Vibration Analysis System.zip
- Codigos_Matlab
  |- Classificadores.zip
  |- Simulacao_Rotor.zip
</pre>

#### Vibration Analysis System.zip:

Este arquivo contém o código fonte do sistema de aquisição de dados desenvolvido em LabView para coleta dos sinais de vibração e do tacômetro.

#### Classificadores.zip:

Neste arquivo foram armazenados os padrões (imagens) para treinamento e teste, obtidos via simulação computacional e ensaios experimentais, e os códigos dos diferentes métodos de classificação analisados nesse trabalho de pesquisa. O conteúdo desse arquivo está organizado da seguinte forma:

*   00_DATA: base de dados de imagens para treinamento e teste;
*   01_CNN: rede neural convolucional;
*   02_PCASVM: PCA com SVM;
*   03_PCAKNN: PCA com kNN;
*   04_PCAQDA: PCA com análise discriminante quadrática;
*   05_RSKNN: ensemble (random subspace) de kNN;
*   06_KNN: k-vizinhos mais próximos;
*   07_SVM: máquinas de vetores de suporte;
*   08_QDA: análise discriminante quadrática;
*   09_PCABTREE: PCA com ensemble (bagging) de árvore de decisão;
*   10_PCAATREE: PCA com ensemble (adaboost) de árvore de decisão;
*   11_LVQ: quantização vetorial por aprendizado;
*   12_PCACNN: PCA com CNN;
*   13_NBAYES: naive Bayes;
*   14_PCALVQ: PCA com quantização vetorial por aprendizado;
*   15_PCANBAYES: PCA com naive Bayes;
*   16_SAE: autocodificadores epilhados;
*   17_AESVM: autocodificador com SVM;
*   18_AEKNN: autocodificador com kNN.

#### Simulacao_Rotor.zip:

Este arquivo contém códigos de modelo em elementos finitos de sistema rotor-mancal para geração dos padrões de treinamento e teste a partir da simulação computacional.

### Execução da simulação computacional:

Para a simulação computacional do sistema rotodinâmico e geração dos padrões de treinamento e teste, basta executar os códigos do arquivo Simulacao_Rotor.zip com prefixo "rotorsystem".

Por exemplo, o arquivo MATLAB "rotorsystem_Cra_n7_9_11_13_15.m" gera os padrões para trinca transversal com o disco nas posições dos nós 7, 9, 11, 13 e 15.

**Data:** 02/04/2021
 
 ### Licença
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
