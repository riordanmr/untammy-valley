// Mark Riordan   2026-02-21 with help from Microsoft Copilot

import Foundation

struct QuizQuestion {
    let subject: String
    let question: String
    let options: [String]
    let background: String? // nil for Math later
}

let quizQuestions: [QuizQuestion] = [

    QuizQuestion(
        subject: "US History",
        question: "What was the main purpose of the Declaration of Independence?",
        options: [
            "To formally break away from Great Britain",
            "To create the U.S. Constitution",
            "To end the Civil War",
            "To purchase land from France"
        ],
        background: "The Declaration of Independence (1776) explained why the American colonies were separating from British rule."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Who was the primary author of the Declaration of Independence?",
        options: [
            "Thomas Jefferson",
            "George Washington",
            "Benjamin Franklin",
            "John Adams"
        ],
        background: "Thomas Jefferson is credited as the principal writer of the Declaration of Independence drafted in 1776."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which event is often considered the start of the American Revolution?",
        options: [
            "The Battle of Lexington and Concord",
            "The Boston Tea Party",
            "The signing of the Constitution",
            "The Louisiana Purchase"
        ],
        background: "The first armed conflict between colonial militias and British troops at Lexington and Concord in 1775 is commonly seen as the war's opening."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main weakness of the Articles of Confederation?",
        options: [
            "It gave too little power to the national government",
            "It gave too much power to the president",
            "It created a strong national army",
            "It allowed the king of England to veto laws"
        ],
        background: "Under the Articles of Confederation the national government lacked strong authority to tax, regulate trade, or enforce laws."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What is the name of the first ten amendments to the U.S. Constitution?",
        options: [
            "The Bill of Rights",
            "The Federalist Papers",
            "The Great Compromise",
            "The Emancipation Proclamation"
        ],
        background: "The first ten amendments added to the Constitution are collectively known as the Bill of Rights and protect individual liberties."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which purchase in 1803 doubled the size of the United States?",
        options: [
            "The Louisiana Purchase",
            "The Alaska Purchase",
            "The Gadsden Purchase",
            "The Oregon Purchase"
        ],
        background: "In 1803 the United States bought a vast territory from France in the Louisiana Purchase, greatly expanding the nation."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Who was president of the United States during the War of 1812?",
        options: [
            "James Madison",
            "George Washington",
            "Andrew Jackson",
            "James Monroe"
        ],
        background: "James Madison served as U.S. president during the War of 1812 between the United States and Great Britain."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main goal of the Monroe Doctrine?",
        options: [
            "To warn European powers not to interfere in the Western Hemisphere",
            "To encourage European colonization in the Americas",
            "To form a military alliance with Britain",
            "To divide North America among European nations"
        ],
        background: "The Monroe Doctrine declared that European interference in the Americas would be viewed as hostile to U.S. interests."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which reform movement in the 1800s focused on ending slavery in the United States?",
        options: [
            "Abolitionist movement",
            "Temperance movement",
            "Women’s suffrage movement",
            "Progressive movement"
        ],
        background: "The abolitionist movement of the 19th century worked to end slavery across the United States."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which territory did the United States gain after winning the Mexican–American War?",
        options: [
            "The Southwest, including California",
            "Florida",
            "The Oregon Territory",
            "Alaska"
        ],
        background: "After the Mexican–American War (1846–1848), the U.S. acquired large southwestern territories, including California."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main issue that led to the Missouri Compromise of 1820?",
        options: [
            "The balance of free and slave states",
            "Tariffs on imported goods",
            "Voting rights for women",
            "Native American removal"
        ],
        background: "The Missouri Compromise addressed how new states would be admitted as free or slave states to preserve a balance in Congress."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Who was the U.S. president most closely associated with the policy of Indian Removal?",
        options: [
            "Andrew Jackson",
            "Abraham Lincoln",
            "James K. Polk",
            "John Quincy Adams"
        ],
        background: "President Andrew Jackson supported and enforced policies that led to the forced relocation of many Native American nations."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the Trail of Tears?",
        options: [
            "The forced march of Native Americans to lands in the West",
            "A route used by pioneers heading to Oregon",
            "A path used by escaped slaves to reach Canada",
            "A Civil War battlefield in Virginia"
        ],
        background: "The Trail of Tears refers to the deadly forced relocation of the Cherokee and other tribes to lands west of the Mississippi."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main goal of the Seneca Falls Convention of 1848?",
        options: [
            "To promote women’s rights, including the right to vote",
            "To end slavery immediately",
            "To support westward expansion",
            "To oppose immigration from Europe"
        ],
        background: "The Seneca Falls Convention was an early organized demand for women's rights, notably calling for suffrage and legal equality."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which novel by Harriet Beecher Stowe increased Northern opposition to slavery?",
        options: [
            "Uncle Tom’s Cabin",
            "The Scarlet Letter",
            "Moby-Dick",
            "The Red Badge of Courage"
        ],
        background: "Harriet Beecher Stowe's novel Uncle Tom’s Cabin depicted the harsh realities of slavery and influenced Northern public opinion."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main result of the Dred Scott decision in 1857?",
        options: [
            "Congress was told it could not ban slavery in the territories",
            "Slavery was abolished in all states",
            "Enslaved people were declared citizens",
            "The Missouri Compromise was strengthened"
        ],
        background: "The Supreme Court's Dred Scott decision ruled that Congress could not prohibit slavery in U.S. territories, worsening sectional tensions."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Who was president of the United States during the Civil War?",
        options: [
            "Abraham Lincoln",
            "Ulysses S. Grant",
            "Andrew Johnson",
            "James Buchanan"
        ],
        background: "Abraham Lincoln led the United States through the Civil War and issued policies aimed at preserving the Union."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the primary goal of the Emancipation Proclamation?",
        options: [
            "To free enslaved people in the Confederate states",
            "To end slavery in the entire United States immediately",
            "To give women the right to vote",
            "To create a new Constitution"
        ],
        background: "Lincoln's Emancipation Proclamation declared freedom for enslaved people in Confederate-held territories as a war measure."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which battle is often considered the turning point of the Civil War?",
        options: [
            "Battle of Gettysburg",
            "Battle of Antietam",
            "Battle of Bull Run",
            "Battle of Shiloh"
        ],
        background: "The Union victory at Gettysburg in 1863 halted a major Confederate invasion and is widely seen as a turning point."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which amendment to the U.S. Constitution officially abolished slavery?",
        options: [
            "13th Amendment",
            "14th Amendment",
            "15th Amendment",
            "10th Amendment"
        ],
        background: "The 13th Amendment, ratified after the Civil War, legally abolished slavery throughout the United States."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main purpose of Reconstruction after the Civil War?",
        options: [
            "To rebuild the South and readmit Southern states to the Union",
            "To expand the U.S. into Canada",
            "To start a new war with Europe",
            "To remove the president from office"
        ],
        background: "Reconstruction was the federal effort to rebuild the South, integrate formerly enslaved people into society, and restore state governments."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which group’s rights were most directly protected by the 15th Amendment?",
        options: [
            "Formerly enslaved men",
            "Women",
            "Native Americans",
            "Immigrants from Europe"
        ],
        background: "The 15th Amendment prohibited denying a citizen the right to vote based on race, protecting voting rights for formerly enslaved men."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main goal of the Homestead Act of 1862?",
        options: [
            "To give free land in the West to settlers",
            "To end slavery in the border states",
            "To force Native Americans to move east",
            "To build factories in the North"
        ],
        background: "The Homestead Act encouraged westward settlement by granting land to settlers who would farm it for several years."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was one major effect of the transcontinental railroad?",
        options: [
            "It made travel and trade across the country much faster",
            "It ended immigration to the United States",
            "It stopped conflicts with Native Americans",
            "It caused the Civil War to start"
        ],
        background: "The completion of the transcontinental railroad connected East and West, speeding movement of people and goods across the nation."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main goal of the Progressive movement in the early 1900s?",
        options: [
            "To address social and political problems caused by industrialization",
            "To restore the monarchy",
            "To expand slavery into new territories",
            "To end public education"
        ],
        background: "Progressive reformers sought to fix problems from rapid industrial growth, such as corruption, unsafe workplaces, and urban poverty."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which event led directly to the United States entering World War I?",
        options: [
            "The Zimmermann Telegram and unrestricted submarine warfare",
            "The bombing of Pearl Harbor",
            "The assassination of Archduke Franz Ferdinand",
            "The sinking of the Lusitania"
        ],
        background: "German submarine attacks and the Zimmermann Telegram pushed the U.S. to abandon neutrality and enter World War I in 1917."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was one major cause of the Great Depression?",
        options: [
            "Overproduction and the stock market crash of 1929",
            "High taxes on the wealthy",
            "Too much government regulation of banks",
            "The end of World War II"
        ],
        background: "Economic imbalances, overproduction, and the 1929 stock market crash contributed to the widespread economic collapse known as the Great Depression."
    ),

    QuizQuestion(
        subject: "US History",
        question: "Which U.S. president is most associated with the New Deal?",
        options: [
            "Franklin D. Roosevelt",
            "Herbert Hoover",
            "Harry S. Truman",
            "Dwight D. Eisenhower"
        ],
        background: "Franklin D. Roosevelt introduced the New Deal, a series of programs to provide relief and recovery during the Great Depression."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What event brought the United States into World War II?",
        options: [
            "Japan’s attack on Pearl Harbor",
            "Germany’s invasion of Poland",
            "The bombing of London",
            "The signing of the Treaty of Versailles"
        ],
        background: "The Japanese attack on Pearl Harbor in December 1941 led the United States to declare war and enter World War II."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the main purpose of the Marshall Plan after World War II?",
        options: [
            "To rebuild the economies of Western European countries",
            "To punish Germany and Japan",
            "To start a new war with the Soviet Union",
            "To end the United Nations"
        ],
        background: "The Marshall Plan provided U.S. financial aid to help Western Europe recover economically after World War II."
    ),

    QuizQuestion(
        subject: "US History",
        question: "What was the primary goal of the Civil Rights Movement of the 1950s and 1960s?",
        options: [
            "To gain equal rights and end racial segregation",
            "To end Prohibition",
            "To expand U.S. territory",
            "To lower the voting age to 16"
        ],
        background: "The Civil Rights Movement aimed to secure equal legal rights and end racial segregation and discrimination against African Americans."
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the value of (2 + 3)?",
        options: [
            "5",
            "4",
            "6",
            "3"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is (7 - 4)?",
        options: [
            "3",
            "2",
            "4",
            "5"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is (6 × 5)?",
        options: [
            "30",
            "11",
            "35",
            "25"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is (20 ÷ 4)?",
        options: [
            "5",
            "4",
            "6",
            "8"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the perimeter of a rectangle with length 8 and width 3?",
        options: [
            "22",
            "11",
            "24",
            "32"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the area of a rectangle with length 7 and width 4?",
        options: [
            "28",
            "11",
            "22",
            "14"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the area of a triangle with base 10 and height 6?",
        options: [
            "30",
            "60",
            "16",
            "40"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the value of the expression (3^2)?",
        options: [
            "9",
            "6",
            "8",
            "12"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the square root of 81?",
        options: [
            "9",
            "8",
            "7",
            "6"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "If a line passes through points (1, 2) and (3, 6), what is its slope?",
        options: [
            "2",
            "1",
            "3",
            "4"
        ],
        background: "Slope is calculated as (change in y) / (change in x). It can be negative."
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Solve for x: (x + 5 = 12).",
        options: [
            "7",
            "6",
            "8",
            "5"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Solve for x: (2x = 14).",
        options: [
            "7",
            "6",
            "14",
            "12"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Solve for x: (x - 9 = 3).",
        options: [
            "12",
            "6",
            "3",
            "9"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is 25% of 80?",
        options: [
            "20",
            "25",
            "15",
            "10"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is 10% of 250?",
        options: [
            "25",
            "10",
            "20",
            "15"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Which of these is a prime number?",
        options: [
            "17",
            "15",
            "21",
            "27"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the mean (average) of the numbers 4, 6, and 10?",
        options: [
            "6.6666666667",
            "5",
            "7",
            "8"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the median of the numbers 3, 7, 9, 2, 5?",
        options: [
            "5",
            "3",
            "7",
            "9"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "If a pizza is cut into 8 equal slices and you eat 3 slices, what fraction of the pizza remains?",
        options: [
            "5/8",
            "3/8",
            "1/2",
            "2/3"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is ((2 + 3) × 4) using order of operations?",
        options: [
            "20",
            "14",
            "24",
            "10"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "A shirt costs $30. During a 20% off sale, what is the sale price?",
        options: [
            "$24",
            "$20",
            "$26",
            "$18"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "If a car travels 60 miles in 1.5 hours, what is its average speed in miles per hour?",
        options: [
            "40",
            "30",
            "45",
            "60"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Which pair of angles are complementary?",
        options: [
            "30° and 60°",
            "45° and 45°",
            "90° and 0°",
            "60° and 60°"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the perimeter of an equilateral triangle with side length 6?",
        options: [
            "18",
            "12",
            "6",
            "24"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "If (y = 3x), what is y when x = 4?",
        options: [
            "12",
            "7",
            "16",
            "8"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is (1/2 + 1/4)?",
        options: [
            "3/4",
            "1/4",
            "2/3",
            "1"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "If you roll a fair six-sided die, what is the probability of rolling a 4?",
        options: [
            "1/6",
            "1/4",
            "1/3",
            "1/2"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "Which expression represents 'five more than twice a number x'?",
        options: [
            "2x + 5",
            "5x + 2",
            "2(x + 5)",
            "x + 7"
        ],
        background: nil
    ),

    QuizQuestion(
        subject: "Mathematics",
        question: "What is the length of the hypotenuse of a right triangle with legs 3 and 4?",
        options: [
            "5",
            "6",
            "7",
            "4"
        ],
        background: nil
    ),
    


    QuizQuestion(
        subject: "English",
        question: "Which word is a synonym for 'happy'?",
        options: [
            "Joyful",
            "Angry",
            "Bitter",
            "Reluctant"
        ],
        background: "A synonym is a word that has a similar meaning; 'joyful' shares meaning with 'happy'."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence uses correct subject-verb agreement?",
        options: [
            "The dog barks every morning.",
            "The dogs barks every morning.",
            "The dog bark every morning.",
            "The dogs barking every morning."
        ],
        background: "Subject-verb agreement means the verb must match the subject in number; a singular subject takes a singular verb."
    ),

    QuizQuestion(
        subject: "English",
        question: "What is the main idea of a paragraph?",
        options: [
            "The central point the paragraph is trying to communicate",
            "A minor detail mentioned in passing",
            "The first sentence only",
            "A list of unrelated facts"
        ],
        background: "The main idea is the primary message or point that a paragraph or passage conveys."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which punctuation mark correctly ends an exclamatory sentence?",
        options: [
            "An exclamation point",
            "A comma",
            "A semicolon",
            "A colon"
        ],
        background: "An exclamation point is used to show strong feeling or emphasis at the end of a sentence."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which of the following is an example of a simile?",
        options: [
            "Her smile was like sunshine.",
            "The wind whispered.",
            "Time is a thief.",
            "The classroom was a zoo."
        ],
        background: "A simile compares two things using 'like' or 'as'; 'like sunshine' shows a direct comparison."
    ),

    QuizQuestion(
        subject: "English",
        question: "What does the prefix 'un-' usually mean in English words?",
        options: [
            "Not or opposite of",
            "Before",
            "Again",
            "Very"
        ],
        background: "Prefixes change a word's meaning; 'un-' commonly negates the base word (e.g., unhappy = not happy)."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence demonstrates correct use of a comma in a compound sentence?",
        options: [
            "I wanted to go for a walk, but it started to rain.",
            "I wanted to go for a walk but, it started to rain.",
            "I wanted to go for a walk but it started to rain.",
            "I wanted, to go for a walk but it started to rain."
        ],
        background: "A comma before a coordinating conjunction (and, but, or, so, etc.) separates two independent clauses in a compound sentence."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which word is an antonym of 'generous'?",
        options: [
            "Stingy",
            "Kind",
            "Giving",
            "Charitable"
        ],
        background: "An antonym is a word with the opposite meaning; 'stingy' is the opposite of 'generous'."
    ),

    QuizQuestion(
        subject: "English",
        question: "What is the narrator's point of view in a story told using 'I'?",
        options: [
            "First person",
            "Second person",
            "Third person limited",
            "Third person omniscient"
        ],
        background: "First-person narration uses 'I' and presents the story from the narrator's personal perspective."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence correctly uses a semicolon?",
        options: [
            "I have a big test tomorrow; I can't go out tonight.",
            "I have a big test tomorrow, I can't go out tonight.",
            "I have a big test tomorrow: I can't go out tonight.",
            "I have a big test tomorrow. I can't go out tonight;"
        ],
        background: "A semicolon links two closely related independent clauses without a conjunction."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which literary device gives human traits to nonhuman things?",
        options: [
            "Personification",
            "Metaphor",
            "Alliteration",
            "Hyperbole"
        ],
        background: "Personification attributes human qualities to animals, objects, or ideas to create vivid imagery."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence shows correct use of an apostrophe for possession?",
        options: [
            "The student's book is on the desk.",
            "The students book is on the desk.",
            "The students' book is on the desk.",
            "The students book's is on the desk."
        ],
        background: "An apostrophe plus 's' indicates possession for a singular noun; 'student's' shows the book belongs to one student."
    ),

    QuizQuestion(
        subject: "English",
        question: "What is the best definition of 'theme' in literature?",
        options: [
            "The underlying message or central idea of a work",
            "The sequence of events in a story",
            "The time and place of the story",
            "A list of characters"
        ],
        background: "Theme is the deeper meaning or message the author conveys through plot, characters, and events."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which transition word best shows contrast between two ideas?",
        options: [
            "However",
            "Furthermore",
            "Similarly",
            "Consequently"
        ],
        background: "Transition words like 'however' signal contrast or an opposing idea between sentences or clauses."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence uses passive voice?",
        options: [
            "The cake was eaten by the children.",
            "The children ate the cake.",
            "The children are eating the cake.",
            "The children will eat the cake."
        ],
        background: "Passive voice places the object before the verb and often includes a form of 'to be' plus a past participle."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which word best completes the sentence: 'She has _____ patience with beginners'?",
        options: [
            "great",
            "greater",
            "greatest",
            "most great"
        ],
        background: "Choose the adjective form that correctly fits the sentence structure and meaning."
    ),

    QuizQuestion(
        subject: "English",
        question: "What does 'infer' mean when reading a text?",
        options: [
            "To draw a conclusion based on evidence and reasoning",
            "To summarize the entire text",
            "To copy the author's words exactly",
            "To list every detail in the passage"
        ],
        background: "Inferring requires using clues from the text plus prior knowledge to reach a logical conclusion."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which of the following is an example of alliteration?",
        options: [
            "Sally sells seashells by the seashore.",
            "The sun set in the west.",
            "He ran as fast as a cheetah.",
            "The room was a refrigerator."
        ],
        background: "Alliteration repeats initial consonant sounds in nearby words to create rhythm or emphasis."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence demonstrates correct pronoun-antecedent agreement?",
        options: [
            "Every student must bring his or her pencil.",
            "Every student must bring their pencil.",
            "Every students must bring his pencil.",
            "Every student must bring its pencil."
        ],
        background: "Pronouns must agree in number with their antecedents; 'every student' is singular, so use 'his or her'."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which choice best describes an author's purpose when writing to persuade?",
        options: [
            "To convince the reader to adopt a viewpoint or take action",
            "To entertain with a fictional story",
            "To provide a neutral list of facts",
            "To describe a scene in detail"
        ],
        background: "Persuasive writing aims to influence the reader's beliefs or actions through arguments and evidence."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which word has a negative connotation compared to 'slim'?",
        options: [
            "Scrawny",
            "Thin",
            "Lean",
            "Slender"
        ],
        background: "Connotation refers to the emotional or cultural associations of a word beyond its literal meaning."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence best shows correct parallel structure?",
        options: [
            "She likes hiking, swimming, and biking.",
            "She likes hiking, to swim, and biking.",
            "She likes hiking, swimming, and to bike.",
            "She likes to hike, swimming, and biking."
        ],
        background: "Parallel structure uses the same grammatical form for items in a list to improve clarity and flow."
    ),

    QuizQuestion(
        subject: "English",
        question: "What is an example of an effective topic sentence for a paragraph about recycling?",
        options: [
            "Recycling reduces waste and conserves natural resources.",
            "Many people recycle in different ways.",
            "There are bins for paper, plastic, and glass.",
            "Some people forget to recycle sometimes."
        ],
        background: "A topic sentence states the main idea of a paragraph clearly and directly."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which literary device is used when an author exaggerates for effect?",
        options: [
            "Hyperbole",
            "Irony",
            "Metaphor",
            "Onomatopoeia"
        ],
        background: "Hyperbole is deliberate exaggeration used to emphasize a point or create humor."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence best demonstrates correct use of quotation marks?",
        options: [
            "She said, \"I'll be there soon.\"",
            "She said, \"I'll be there soon.",
            "She said, I'll be there soon.\"",
            "She said, 'I'll be there soon.\""
        ],
        background: "Quotation marks enclose exact words spoken or written by someone else and require matching opening and closing marks."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which choice identifies the tone of a passage that uses formal language and respectful praise?",
        options: [
            "Respectful and formal",
            "Sarcastic and mocking",
            "Casual and humorous",
            "Angry and accusatory"
        ],
        background: "Tone reflects the author's attitude toward the subject and is revealed through word choice and style."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence best shows correct use of a colon?",
        options: [
            "Bring the following items: a pencil, a notebook, and an eraser.",
            "Bring: the following items a pencil, a notebook, and an eraser.",
            "Bring the following items, a pencil: a notebook and an eraser.",
            "Bring the following items a pencil, a notebook, and an eraser:"
        ],
        background: "A colon introduces a list, explanation, or quotation that follows an independent clause."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which element of plot refers to the sequence of events in a story?",
        options: [
            "Plot",
            "Theme",
            "Tone",
            "Setting"
        ],
        background: "Plot is the organized sequence of events that make up a story, including conflict and resolution."
    ),

    QuizQuestion(
        subject: "English",
        question: "Which sentence best demonstrates concise academic writing?",
        options: [
            "The study shows that exercise improves mood.",
            "It is a well-known fact that exercise has been shown to improve mood in many cases.",
            "Exercise, which many people do, can sometimes improve mood for some individuals.",
            "There are numerous instances in which exercise might be associated with mood changes."
        ],
        background: "Concise academic writing states ideas clearly and directly without unnecessary words or repetition."
    ),



    QuizQuestion(
        subject: "Science",
        question: "What is the basic unit of life?",
        options: [
            "Cell",
            "Atom",
            "Molecule",
            "Organ"
        ],
        background: "Biology defines the cell as the smallest structure capable of performing all life functions."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which process do plants use to convert sunlight into chemical energy?",
        options: [
            "Photosynthesis",
            "Respiration",
            "Fermentation",
            "Transpiration"
        ],
        background: "Photosynthesis is the process by which plants use light energy to make sugars from carbon dioxide and water."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What gas do animals exhale as a waste product of respiration?",
        options: [
            "Carbon dioxide",
            "Oxygen",
            "Nitrogen",
            "Hydrogen"
        ],
        background: "Cellular respiration in animals produces carbon dioxide as a byproduct that is exhaled."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which particle in an atom has a positive charge?",
        options: [
            "Proton",
            "Electron",
            "Neutron",
            "Photon"
        ],
        background: "An atom's nucleus contains protons, which carry a positive electrical charge."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the chemical formula for water?",
        options: [
            "H2O",
            "CO2",
            "O2",
            "NaCl"
        ],
        background: "Water is composed of two hydrogen atoms bonded to one oxygen atom, written H2O."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which force keeps planets in orbit around the Sun?",
        options: [
            "Gravity",
            "Magnetism",
            "Friction",
            "Electrostatic force"
        ],
        background: "Gravity is the attractive force between masses that governs planetary orbits."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the term for a change of state from liquid to gas?",
        options: [
            "Evaporation",
            "Condensation",
            "Freezing",
            "Sublimation"
        ],
        background: "Evaporation is the process where molecules leave a liquid and become a gas at the surface."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which organ system is primarily responsible for transporting oxygen and nutrients throughout the body?",
        options: [
            "Circulatory system",
            "Digestive system",
            "Nervous system",
            "Endocrine system"
        ],
        background: "The circulatory system, including the heart and blood vessels, moves oxygen and nutrients to cells."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is an example of a physical change?",
        options: [
            "Melting ice",
            "Burning wood",
            "Rusting iron",
            "Baking a cake"
        ],
        background: "Melting ice changes the state of water without altering its chemical composition, so it is a physical change."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which organelle is known as the 'powerhouse of the cell'?",
        options: [
            "Mitochondrion",
            "Nucleus",
            "Ribosome",
            "Golgi apparatus"
        ],
        background: "Mitochondria generate ATP through cellular respiration, supplying energy for the cell."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What type of bond involves sharing electrons between atoms?",
        options: [
            "Covalent bond",
            "Ionic bond",
            "Hydrogen bond",
            "Metallic bond"
        ],
        background: "Covalent bonds form when atoms share pairs of electrons to achieve stable electron configurations."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which layer of Earth is liquid and generates Earth's magnetic field through convection?",
        options: [
            "Outer core",
            "Inner core",
            "Mantle",
            "Crust"
        ],
        background: "The outer core is molten iron and nickel; its motion helps produce Earth's magnetic field."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the primary gas in Earth's atmosphere?",
        options: [
            "Nitrogen",
            "Oxygen",
            "Carbon dioxide",
            "Argon"
        ],
        background: "Nitrogen makes up about 78% of Earth's atmosphere by volume, the largest component."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which process increases genetic variation by mixing parental genes during sexual reproduction?",
        options: [
            "Meiosis",
            "Mitosis",
            "Binary fission",
            "Cloning"
        ],
        background: "Meiosis produces gametes with shuffled genetic material, increasing variation in offspring."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the SI unit for measuring force?",
        options: [
            "Newton",
            "Joule",
            "Watt",
            "Pascal"
        ],
        background: "Force is measured in newtons (N) in the International System of Units (SI)."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which process describes water moving through a plant from roots to leaves and evaporating from leaf surfaces?",
        options: [
            "Transpiration",
            "Photosynthesis",
            "Respiration",
            "Osmosis"
        ],
        background: "Transpiration is the evaporation of water from plant leaves, driving upward water movement."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What type of energy is stored in a stretched spring?",
        options: [
            "Potential energy",
            "Kinetic energy",
            "Thermal energy",
            "Chemical energy"
        ],
        background: "Potential energy is stored energy due to an object's position or configuration, such as a stretched spring."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which pH value represents a neutral solution at 25°C?",
        options: [
            "7",
            "0",
            "14",
            "1"
        ],
        background: "A pH of 7 is neutral, indicating equal concentrations of hydrogen and hydroxide ions in pure water."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the main function of red blood cells?",
        options: [
            "Transport oxygen",
            "Fight infections",
            "Clot blood",
            "Produce hormones"
        ],
        background: "Red blood cells contain hemoglobin, which binds and carries oxygen to body tissues."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which phenomenon explains why white light separates into colors when passing through a prism?",
        options: [
            "Refraction and dispersion",
            "Reflection",
            "Diffraction",
            "Interference"
        ],
        background: "Dispersion occurs because different wavelengths refract by different amounts, separating white light into colors."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which organ in the human body is primarily responsible for filtering blood and producing urine?",
        options: [
            "Kidney",
            "Liver",
            "Lungs",
            "Pancreas"
        ],
        background: "Kidneys filter waste from the blood and regulate water and electrolyte balance by producing urine."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the term for a species that no longer exists anywhere on Earth?",
        options: [
            "Extinct",
            "Endangered",
            "Threatened",
            "Invasive"
        ],
        background: "Extinction means a species has died out completely and no living individuals remain."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which law states that for every action there is an equal and opposite reaction?",
        options: [
            "Newton's third law",
            "Newton's first law",
            "Newton's second law",
            "Law of universal gravitation"
        ],
        background: "Newton's third law describes how forces between two interacting objects are equal in magnitude and opposite in direction."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which type of rock forms from cooling and solidification of magma or lava?",
        options: [
            "Igneous rock",
            "Sedimentary rock",
            "Metamorphic rock",
            "Fossil rock"
        ],
        background: "Igneous rocks crystallize from molten material (magma or lava) as it cools and solidifies."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the main role of decomposers in an ecosystem?",
        options: [
            "Break down dead organisms and recycle nutrients",
            "Produce energy through photosynthesis",
            "Consume primary producers only",
            "Prevent erosion"
        ],
        background: "Decomposers like fungi and bacteria break down organic matter, returning nutrients to the soil."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which device measures electric current in a circuit?",
        options: [
            "Ammeter",
            "Voltmeter",
            "Ohmmeter",
            "Thermometer"
        ],
        background: "An ammeter is connected in series to measure the flow of electric current in amperes."
    ),

    QuizQuestion(
        subject: "Science",
        question: "What is the primary cause of seasons on Earth?",
        options: [
            "Tilt of Earth's axis",
            "Distance from the Sun",
            "Earth's orbital speed",
            "Solar flares"
        ],
        background: "Seasons result mainly from Earth's axial tilt, which changes the angle and intensity of sunlight during the year."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which macromolecule is the main source of quick energy for cells?",
        options: [
            "Carbohydrates",
            "Lipids",
            "Proteins",
            "Nucleic acids"
        ],
        background: "Carbohydrates like glucose are readily used by cells to produce ATP for immediate energy needs."
    ),

    QuizQuestion(
        subject: "Science",
        question: "Which process moves molecules from an area of higher concentration to an area of lower concentration without energy input?",
        options: [
            "Diffusion",
            "Active transport",
            "Endocytosis",
            "Exocytosis"
        ],
        background: "Diffusion is the passive movement of particles down their concentration gradient until equilibrium is reached."
    )

    
    
]

