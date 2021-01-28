
def parse(i_path:str, o_path:str, model):
    with open(i_path) as f_in:
        with open(o_path, 'w') as f_out:            
            for line in f_in:
                line_tok = model.encode_as_pieces(line)
                parsed = ''
                tok_iter = iter(line_tok)
                while True:
                    try:
                        tok = next(tok_iter)
                        if tok == '▁':
                            # This indicates that the next token is a whole word  
                            # and we will add that word to the parsed text

                            parsed += ' ' + next(tok_iter)
                        elif tok[0] == '▁':
                            # If the first sign is a "_" then we know that the word was not split 
                            # up here but in the next one. We will add this word but we don't need the 
                            # sign 
                
                            parsed += ' ' + tok[1:]
                        elif '▁' not in tok:
                            # if there is no sign here then the word was split up add this
                            # character. We will add it to the parsed sentece with a space
                            # and a sign
                        
                            parsed += ' ▁' + tok 
                        else:
                            # Nothing should end here
                            print('Should not be here')
                            print(tok)


                    except StopIteration:
                        break

                # Lets change the format of the separtor
                parsed = re.sub(' ▁', '@@ ', parsed.strip())
                f_out.write(parsed+'\n')    

if __name__ == "__main__":
    import sentencepiece as spm
    from os.path import join, exists
    from os import mkdir
    import re   
    import sys
    from subprocess import run, STDOUT
    import time

    t0 = time.time()


    #training_set = '../../LM_corpus/demo_files/small_train_corpus'
    #test_set = '../../LM_corpus/demo_files/small_test_corpus'
    training_set = '../../LM_corpus/rmh_train_smaller'
    test_set = '../../LM_corpus/rmh_test_smaller'


    # Parameters
    code=sys.argv[1]
    vocab_size=str(sys.argv[2])
    code = code+'_'+str(vocab_size)
    order=6

    if not exists(code):
        mkdir(code)

    model_prefix = join(code, 'spm'+str(vocab_size))

    model='bpe'

    print(f'Training a {model} model')

    # vocab_size - type: int32 default: 8000
    # model_type - unigram, char, word, bpe
    # normalization_rule_name - (Normalization rule name. Choose from nfkc or identity) identity means no normalization
    # train_extremely_large_corpus - Increase bit depth for unigram tokenization.) 
    # all flags are here https://github.com/google/sentencepiece/blob/master/doc/options.md
    # Colab demo here https://colab.research.google.com/github/google/sentencepiece/blob/master/python/sentencepiece_python_module_example.ipynb#scrollTo=Lf5Fs_pPIKif
    # max_sentencepiece_length (maximum length of sentence piece)  type: int32 default: 16

    spm.SentencePieceTrainer.train(input=training_set, \
                                model_prefix=model_prefix, \
                                vocab_size=vocab_size, \
                                model_type=model, \
                                normalization_rule_name='identity', \
                                max_sentencepiece_length=64,\
                                train_extremely_large_corpus=False) #Increase bit depth for unigram tokenization
    t1 = time.time()
    print(f"Training a {model} model {t1-t0} sek")

    sp = spm.SentencePieceProcessor()
    sp.load(model_prefix+'.model')

    parse(training_set, join(code, "rmh_training"), sp)
    parse(test_set, join(code, "rmh_test"), sp)

    run(f"./../create_lm.sh {code} {order}", \
                    shell=True, \
                    stderr=STDOUT)

    t_end = time.time()
    print(f"Total runtime: {t_end-t0} sek")
