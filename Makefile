NORM_FILE := ""

STATSIMI := statsimi

# in meters
CUTOFFDIST := 1000

# probability that a station is spiced
SPICE := --spice=0.5

EVAL_RUNS := 5

# arguments for building the pairs files, use 20% as training, 80% as test data (-p 0.2)
PAIRS_BUILD_ARGS := --unique --clean_data $(SPICE) --cutoffdist=$(CUTOFFDIST) -p 0.2

EVAL_ARGS := --runs=$(EVAL_RUNS) --norm_file=$(NORM_FILE)

EVAL_RES_DIR := data/evaluation_run
GEODATA_DIR := data/geodata
MODEL_DIR := data/models

.SECONDARY:

.PHONY: clean install eval help

help:
	@cat README.md

install: osmfilter osmconvert
	@echo Installing statsimi
	@git clone --recurse-submodules https://github.com/ad-freiburg/statsimi
	@cd statsimi && pip3 install wheel && pip3 install .

eval: $(EVAL_RES_DIR)/uk.eval.tsv $(EVAL_RES_DIR)/dach.eval.tsv

models: $(MODEL_DIR)/uk.model $(MODEL_DIR)/dach.model

osmfilter:
	@echo Installing osmfilter
	@curl -sS --insecure -L http://m.m.i24.cc/osmfilter.c | cc -x c - -O3 -o $@

osmconvert:
	@echo Installing osmconvert
	@curl -sS --insecure -L http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o $@

$(EVAL_RES_DIR)/%/:
	@mkdir -p $@

$(MODEL_DIR)/:
	@mkdir -p $@

$(EVAL_RES_DIR)/%.eval.tsv: $(EVAL_RES_DIR)/%/geodist/output.txt $(EVAL_RES_DIR)/%/editdist/output.txt $(EVAL_RES_DIR)/%/jaccard/output.txt $(EVAL_RES_DIR)/%/ped/output.txt $(EVAL_RES_DIR)/%/bts/output.txt $(EVAL_RES_DIR)/%/jaro/output.txt $(EVAL_RES_DIR)/%/jaro_winkler/output.txt $(EVAL_RES_DIR)/%/tfidf/output.txt $(EVAL_RES_DIR)/%/rf/output.txt $(EVAL_RES_DIR)/%/geodist-editdist/output.txt $(EVAL_RES_DIR)/%/geodist-tfidf/output.txt $(EVAL_RES_DIR)/%/geodist-bts/output.txt $(EVAL_RES_DIR)/%/geodist-jaccard/output.txt
	@echo
	@echo Finished evaluation run for $*.
	@echo This table is saved to $@
	@echo
	@(echo " \tprec\trec\tF1\tmodelargs\tfbargs" && for f in $^; do awk '{s=$$0};END{print FILENAME "\t" s}' $$f;done) | sed "s|$(EVAL_RES_DIR)/$*/||g" | sed "s|/output.txt||g" | column -t -s "$$(printf '\t')" 2>&1 | tee $@

$(EVAL_RES_DIR)/%/geodist/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/geodist/
	@echo == Evaluating geodist thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*geodist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="geodist" --modeltestargs="geodist_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@


$(EVAL_RES_DIR)/%/editdist/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/editdist/
	@echo == Evaluating editdist thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="editdist" --modeltestargs="editdist_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*editdist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="editdist" --modeltestargs="editdist_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@


$(EVAL_RES_DIR)/%/jaccard/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/jaccard/
	@echo == Evaluating jaccard thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="jaccard" --modeltestargs="jaccard_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*jaccard_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="jaccard" --modeltestargs="jaccard_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/tfidf/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/tfidf/
	@echo == Evaluating tfidf thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.train.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="tfidf" --modeltestargs="tfidf_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*tfidf_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data (but still take TFIDF score from the train data!), print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="tfidf" --modeltestargs="tfidf_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/jaro/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/jaro/
	@echo == Evaluating jaro thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="jaro" --modeltestargs="jaro_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*jaro_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="jaro" --modeltestargs="jaro_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/jaro_winkler/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/jaro_winkler/
	@echo == Evaluating jaro_winkler thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="jaro_winkler" --modeltestargs="jaro_winkler_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*jaro_winkler_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="jaro_winkler" --modeltestargs="jaro_winkler_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/bts/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/bts/
	@echo == Evaluating bts thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="bts" --modeltestargs="bts_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*bts_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="bts" --modeltestargs="bts_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/ped/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/ped/
	@echo == Evaluating ped thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="ped" --modeltestargs="ped_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*ped_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="ped" --modeltestargs="ped_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/sed/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/sed/
	@echo == Evaluating sed thresholds for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="sed" --modeltestargs="sed_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --topk 0 --eval-out $|  --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value to $@.ts
	@tail -n1 $@.tmp | sed -re "s/.*sed_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="sed" --modeltestargs="sed_threshold=`cat $@.ts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-editdist/output.txt: $(GEODATA_DIR)/%-stations.test.pairs  $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/geodist-editdist/
	@echo == Evaluating combination of geodist and editdist using soft voting approach for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist, editdist" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;editdist_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --topk 0 --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value for geodist to $@.ts_geo
	@tail -n1 $@.tmp | sed -re "s/.*geodist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_geo
	@# print the best threshold value for edidist to $@.ts_ed
	@tail -n1 $@.tmp | sed -re "s/.*editdist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_ed
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="geodist,editdist" --modeltestargs="geodist_threshold=`cat $@.ts_geo`;editdist_threshold=`cat $@.ts_ed`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-bts/output.txt: $(GEODATA_DIR)/%-stations.test.pairs  $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/geodist-bts/
	@echo == Evaluating combination of geodist and bts using soft voting approach for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist, bts" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;bts_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --topk 0 --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value for geodist to $@.ts_geo
	@tail -n1 $@.tmp | sed -re "s/.*geodist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_geo
	@# print the best threshold value for edidist to $@.ts_ed
	@tail -n1 $@.tmp | sed -re "s/.*bts_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_bts
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="geodist,bts" --modeltestargs="geodist_threshold=`cat $@.ts_geo`;bts_threshold=`cat $@.ts_bts`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-tfidf/output.txt: $(GEODATA_DIR)/%-stations.test.pairs $(GEODATA_DIR)/%-stations.train.pairs $(GEODATA_DIR)/%-stations.test.pairs | $(EVAL_RES_DIR)/%/geodist-tfidf/
	@echo == Evaluating combination of geodist and tfidf using soft voting approach for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.train.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist, tfidf" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;tfidf_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --topk 0 --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value for geodist to $@.ts_geo
	@tail -n1 $@.tmp | sed -re "s/.*geodist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_geo
	@# print the best threshold value for edidist to $@.ts_ed
	@tail -n1 $@.tmp | sed -re "s/.*tfidf_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_tfidf
	@# evaluate the best threshold value on the test data (but still take TFIDF scores from the train data!), print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.test.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist,tfidf" --modeltestargs="geodist_threshold=`cat $@.ts_geo`;tfidf_threshold=`cat $@.ts_tfidf`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/geodist-jaccard/output.txt: $(GEODATA_DIR)/%-stations.test.pairs  $(GEODATA_DIR)/%-stations.train.pairs | $(EVAL_RES_DIR)/%/geodist-jaccard/
	@echo == Evaluating combination of geodist and jaccard using soft voting approach for $* ==
	@# find the best threshold value on the train data
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.train.pairs/* --method="geodist, jaccard" --modeltestargs="geodist_threshold=0.1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300, 350, 400, 450, 500;jaccard_threshold=0.001, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.999" --voting='soft' --topk 0 --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@# print the best threshold value for geodist to $@.ts_geo
	@tail -n1 $@.tmp | sed -re "s/.*geodist_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_geo
	@# print the best threshold value for edidist to $@.ts_ed
	@tail -n1 $@.tmp | sed -re "s/.*jaccard_threshold'\:\ ([0-9]?\.?[0-9]+).*/\1/g" > $@.ts_jaccard
	@# evaluate the best threshold value on the test data, print result
	$(STATSIMI) evaluate-par $(EVAL_ARGS) --test $(GEODATA_DIR)/$*-stations.test.pairs/* --method="geodist,jaccard" --modeltestargs="geodist_threshold=`cat $@.ts_geo`;jaccard_threshold=`cat $@.ts_jaccard`" --topk 0 --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/rf/output.txt: $(GEODATA_DIR)/%-stations.train.pairs $(GEODATA_DIR)/%-stations.test.pairs | $(EVAL_RES_DIR)/%/rf/
	@echo == Evaluating RF for topk=2500 for $* ==
	# train on 100% of the provided test pairs file, which
	# has been created by splitting the original pairs into
	# two random 20%/80% parts
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.test.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="rf" --fbtestargs="topk=2500"  --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/rf_topk/output.txt: $(GEODATA_DIR)/%-stations.train.pairs $(GEODATA_DIR)/%-stations.test.pairs | $(EVAL_RES_DIR)/%/rf_topk/
	@echo == Evaluating topk qgram number for $* ==
	# train on 100% of the provided test pairs file, which
	# has been created by splitting the original pairs into
	# two random 20%/80% parts
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.test.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="rf" --fbtestargs="topk=0, 5, 10, 25, 50, 100, 250, 500, 1000, 1500, 2000, 2500"  --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(EVAL_RES_DIR)/%/rf_pos_pairs/output.txt: $(GEODATA_DIR)/%-stations.train.pairs $(GEODATA_DIR)/%-stations.test.pairs | $(EVAL_RES_DIR)/%/rf_pos_pairs/
	@echo == Evaluating number of pos pairs $* ==
	$(STATSIMI) evaluate-par $(EVAL_ARGS) -p 1 --test $(GEODATA_DIR)/$*-stations.test.pairs/* --train $(GEODATA_DIR)/$*-stations.train.pairs/* --method="rf" --fbtestargs="num_pos_pairs=0, 1, 2, 3, 4, 5" --eval-out $| --model_out "" 2>&1 | tee $@.tmp
	@mv $@.tmp $@

$(MODEL_DIR)/%.model: $(GEODATA_DIR)/%-stations.train.pairs | $(MODEL_DIR)/
	@echo == Building RF model for $* ==
	# train on 100% of the provided test pairs file, which
	# has been created by splitting the original pairs into
	# two random 20%/80% parts
	$(STATSIMI) model --topk 2500 -p 1 --train $(GEODATA_DIR)/$*-stations.train.pairs/1.pairs --method="rf" --model_out $@

$(GEODATA_DIR)/%-stations.osm: $(GEODATA_DIR)/%-latest.o5m | osmfilter
	@echo "Filtering osm stations..."
	@./osmfilter $< --keep="public_transport=stop public_transport=stop_position public_transport=platform public_transport=station public_transport=halt highway=bus_stop railway=stop railway=station railway=halt railway=tram_stop railway=platform tram=stop subway=stop" --keep-relations="public_transport=stop_area public_transport=stop_area_group" --drop-version -o=$@

$(GEODATA_DIR)/%-stations.train.pairs $(GEODATA_DIR)/%-stations.test.pairs: $(GEODATA_DIR)/%-stations.osm
	@echo "Creating station pairs for training and testing..."
	@mkdir -p $(GEODATA_DIR)/$*-stations.train.pairs
	@mkdir -p $(GEODATA_DIR)/$*-stations.test.pairs
	@for NUM in $$(seq 1 $(EVAL_RUNS)) ; do \
		echo " **** Run for test/training set #"$$NUM "****" ; \
		$(STATSIMI) pairs $(PAIRS_BUILD_ARGS) --train $< --pairs_train_out $(GEODATA_DIR)/$*-stations.train.pairs/$$NUM.pairs --pairs_test_out $(GEODATA_DIR)/$*-stations.test.pairs/$$NUM.pairs ; \
	done

$(GEODATA_DIR)/dach-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading DACH OSM stations..."
	@curl --insecure -LSs "http://download.geofabrik.de/europe/dach-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/uk-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading UK OSM stations..."
	@curl --insecure -LSs "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/london-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading London OSM stations..."
	@curl --insecure -LSs "http://download.geofabrik.de/europe/great-britain/england/greater-london-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/freiburg-regbz-latest.o5m:
	@mkdir -p $(GEODATA_DIR)
	@echo "Downloading Freiburg RegBZ OSM stations..."
	@curl --insecure -LSs "http://download.geofabrik.de/europe/germany/baden-wuerttemberg/freiburg-regbez-latest.osm.pbf" | ./osmconvert - --drop-author --drop-version -o=$@

$(GEODATA_DIR)/freiburg-latest.o5m: $(GEODATA_DIR)/freiburg-regbz-latest.o5m | osmconvert
	@mkdir -p $(GEODATA_DIR)
	@./osmconvert $< -b=7.713899,47.9285939,7.973421,48.075549 > $@

clean:
	@rm -rf $(MODEL_DIR)
	@rm -rf $(GEODATA_DIR)
	@rm -rf $(EVAL_RES_DIR)
	@rm -f *.eval.tsv
